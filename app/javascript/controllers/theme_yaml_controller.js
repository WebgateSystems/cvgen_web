import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["catalog", "yaml", "heading", "body", "headingList", "bodyList"]

  connect() {
    this.fonts = this.parseCatalog()
    this.activeRole = null
    this.activeIndex = -1
    this.syncInputsFromYaml()
  }

  parseCatalog() {
    if (!this.hasCatalogTarget) return []
    try {
      return JSON.parse(this.catalogTarget.textContent)
    } catch {
      return []
    }
  }

  filterHeading() {
    this.showMatches("heading")
  }

  filterBody() {
    this.showMatches("body")
  }

  showHeading() {
    this.showMatches("heading")
  }

  showBody() {
    this.showMatches("body")
  }

  headingKeydown(event) {
    this.handleKey(event, "heading")
  }

  bodyKeydown(event) {
    this.handleKey(event, "body")
  }

  headingChanged() {
    this.patchYaml("heading", this.headingTarget.value)
  }

  bodyChanged() {
    this.patchYaml("body", this.bodyTarget.value)
  }

  nameChanged(event) {
    this.setScalar(this.yamlTarget.value, "name", event.target.value, true)
  }

  yamlChanged() {
    this.syncInputsFromYaml()
  }

  pick(event) {
    const role = event.params.role
    const family = event.params.family
    this.applyFamily(role, family)
  }

  closeLists(event) {
    if (this.element.contains(event.target) && event.target.closest(".font-combobox")) return
    this.hideLists()
  }

  showMatches(role) {
    const input = this[`${role}Target`]
    const list = this[`${role}ListTarget`]
    const query = input.value.trim().toLowerCase()
    const matches = this.fonts
      .filter((font) => font.family.toLowerCase().includes(query))
      .sort((a, b) => this.score(a.family, query) - this.score(b.family, query))
      .slice(0, 12)

    list.replaceChildren()
    matches.forEach((font, index) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "font-combobox__option"
      button.textContent = font.family
      button.dataset.action = "mousedown->theme-yaml#pick"
      button.dataset.themeYamlRoleParam = role
      button.dataset.themeYamlFamilyParam = font.family
      if (index === 0) button.classList.add("is-active")
      list.appendChild(button)
    })
    this.activeRole = role
    this.activeIndex = matches.length ? 0 : -1
    list.hidden = matches.length === 0
  }

  handleKey(event, role) {
    const list = this[`${role}ListTarget`]
    if (event.key === "Escape") {
      list.hidden = true
      return
    }
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      if (list.hidden) this.showMatches(role)
      this.moveActive(role, event.key === "ArrowDown" ? 1 : -1)
      return
    }
    if (event.key === "Enter") {
      const active = list.querySelector(".font-combobox__option.is-active")
      if (!list.hidden && active) {
        event.preventDefault()
        this.applyFamily(role, active.dataset.themeYamlFamilyParam)
      }
    }
  }

  moveActive(role, delta) {
    const options = Array.from(this[`${role}ListTarget`].querySelectorAll(".font-combobox__option"))
    if (!options.length) return
    this.activeIndex = (this.activeIndex + delta + options.length) % options.length
    options.forEach((option, index) => option.classList.toggle("is-active", index === this.activeIndex))
    options[this.activeIndex].scrollIntoView({ block: "nearest" })
  }

  applyFamily(role, family) {
    this[`${role}Target`].value = family
    this.patchYaml(role, family)
    this.hideLists()
  }

  hideLists() {
    if (this.hasHeadingListTarget) this.headingListTarget.hidden = true
    if (this.hasBodyListTarget) this.bodyListTarget.hidden = true
    this.activeIndex = -1
  }

  patchYaml(role, family) {
    if (!family.trim() || !this.hasYamlTarget) return
    this.yamlTarget.value = this.setScalar(this.yamlTarget.value, role, family.trim(), false)
  }

  syncInputsFromYaml() {
    if (!this.hasYamlTarget) return
    const yaml = this.yamlTarget.value
    if (this.hasHeadingTarget) this.headingTarget.value = this.readScalar(yaml, "heading")
    if (this.hasBodyTarget) this.bodyTarget.value = this.readScalar(yaml, "body")
  }

  readScalar(yaml, key) {
    const match = yaml.match(new RegExp(`(?:^|\\n)[ \\t]*${key}:[ \\t]*(?:"([^"]*)"|'([^']*)'|(\\S[^\\n]*))`))
    return (match && (match[1] || match[2] || match[3] || "")).trim()
  }

  setScalar(yaml, key, value, topLevel) {
    const quoted = JSON.stringify(value)
    const pattern = topLevel ? new RegExp(`^${key}:[ \\t]*.*$`, "m") : new RegExp(`^([ \\t]*${key}:[ \\t]*).*$`, "m")
    if (!pattern.test(yaml)) return yaml
    const next = yaml.replace(pattern, topLevel ? `${key}: ${quoted}` : `$1${quoted}`)
    if (this.hasYamlTarget) this.yamlTarget.value = next
    return next
  }

  score(family, query) {
    const name = family.toLowerCase()
    if (name === query) return 0
    if (name.startsWith(query)) return 1
    return 2 + name.indexOf(query)
  }
}
