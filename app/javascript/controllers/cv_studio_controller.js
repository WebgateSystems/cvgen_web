import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form", "profile", "version", "theme", "generatorProfile", "layout",
    "scale", "fit", "maxPages", "maxExperience", "includeSkills", "exclude",
    "command", "iframe", "error", "placeholder", "download"
  ]
  static values = {
    previewUrl: String,
    versions: Object,
    generatorProfiles: Array
  }

  connect() {
    this.syncVersions()
    this.updateCommand()
    this.refresh()
  }

  disconnect() {
    clearTimeout(this.refreshTimer)
    if (this.objectUrl) URL.revokeObjectURL(this.objectUrl)
  }

  preventSubmit(event) {
    event.preventDefault()
  }

  onChange(event) {
    if (event.target === this.profileTarget) this.syncVersions()
    if (this.hasGeneratorProfileTarget && event.target === this.generatorProfileTarget) {
      this.applyGeneratorProfile()
    }
    this.scheduleRefresh()
  }

  scheduleRefresh() {
    clearTimeout(this.refreshTimer)
    this.refreshTimer = setTimeout(() => this.refresh(), 150)
  }

  syncVersions() {
    const profileId = this.profileTarget.value
    const versions = this.versionsValue[profileId] || []
    const current = this.versionTarget.value
    this.versionTarget.innerHTML = ""
    versions.forEach((version, index) => {
      const option = document.createElement("option")
      option.value = version.id
      option.textContent = version.label
      if (version.id === current || (!versions.some((item) => item.id === current) && index === 0)) {
        option.selected = true
      }
      this.versionTarget.appendChild(option)
    })
  }

  applyGeneratorProfile() {
    const selected = this.generatorProfilesValue.find((item) => item.name === this.generatorProfileTarget.value)
    if (!selected) return

    this.layoutTarget.value = selected.layout
    this.maxPagesTarget.value = selected.max_pages
    this.maxExperienceTarget.value = selected.max_experience_items || ""
    this.includeSkillsTarget.value = selected.include_skills || ""
    this.excludeTarget.value = selected.exclude || ""

    const themeOption = this.themeTarget.querySelector(`[data-slug="${selected.theme}"]`)
    if (themeOption) this.themeTarget.value = themeOption.value
  }

  copyCommand(event) {
    event.preventDefault()
    navigator.clipboard.writeText(this.commandTarget.textContent)
  }

  updateCommand() {
    const themeOption = this.themeTarget.selectedOptions[0]
    const themeSlug = themeOption?.dataset?.slug || "THEME"
    const scale = this.scaleTarget.value || "1.0"
    const parts = [
      "bundle exec cv build",
      `-c ${this.contentStem()}`,
      `-p ${this.generatorProfileTarget.value}`,
      `-l ${this.layoutTarget.value}`,
      `-t ${themeSlug}`,
      `--scale ${scale}`
    ]
    if (this.fitTarget.checked) parts.push("--fit")
    this.commandTarget.textContent = parts.join(" \\\n  ")
  }

  contentStem() {
    const name = this.profileTarget.selectedOptions[0]?.textContent || "cv"
    const versionLabel = this.versionTarget.selectedOptions[0]?.textContent || "v1"
    const number = (versionLabel.match(/v(\d+)/i) || [])[1] || "1"
    return `${this.slugify(name)}-v${number}`
  }

  slugify(value) {
    return value.toString().toLowerCase().trim()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "") || "cv"
  }

  async refresh() {
    this.updateCommand()
    const params = new URLSearchParams(new FormData(this.formTarget))
    const url = `${this.previewUrlValue}?${params.toString()}`
    this.downloadTarget.href = `${url}&download=1`

    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.hidden = false
      if (this.placeholderTarget.dataset.loading) {
        this.placeholderTarget.textContent = this.placeholderTarget.dataset.loading
      }
    }

    try {
      const response = await fetch(url, { headers: { Accept: "application/pdf" } })
      if (!response.ok) {
        this.showError(await response.text())
        return
      }
      const blob = await response.blob()
      if (this.objectUrl) URL.revokeObjectURL(this.objectUrl)
      this.objectUrl = URL.createObjectURL(blob)
      this.iframeTarget.src = this.objectUrl
      this.iframeTarget.hidden = false
      this.errorTarget.hidden = true
      this.placeholderTarget.hidden = true
    } catch (error) {
      this.showError(error.message)
    }
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.hidden = false
    this.iframeTarget.hidden = true
    this.placeholderTarget.hidden = true
  }
}
