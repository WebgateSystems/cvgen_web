import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "list"]

  connect() {
    this.fonts = this.parseCatalog()
    this.activeIndex = -1
  }

  filter() {
    this.showMatches()
  }

  show() {
    this.showMatches()
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.hide()
      return
    }
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      if (this.listTarget.hidden) this.showMatches()
      this.moveActive(event.key === "ArrowDown" ? 1 : -1)
      return
    }
    if (event.key === "Enter") {
      const active = this.listTarget.querySelector(".font-combobox__option.is-active")
      if (!this.listTarget.hidden && active) {
        event.preventDefault()
        this.apply(active.dataset.family)
      }
    }
  }

  pick(event) {
    this.apply(event.params.family)
  }

  closeIfOutside(event) {
    if (this.element.contains(event.target)) return
    this.hide()
  }

  showMatches() {
    const query = this.inputTarget.value.trim().toLowerCase()
    const matches = this.fonts
      .filter((font) => font.family.toLowerCase().includes(query))
      .sort((a, b) => this.score(a.family, query) - this.score(b.family, query))
      .slice(0, 12)

    this.listTarget.replaceChildren()
    matches.forEach((font, index) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "font-combobox__option"
      button.textContent = font.family
      button.dataset.action = "mousedown->font-picker#pick"
      button.dataset.fontPickerFamilyParam = font.family
      button.dataset.family = font.family
      if (index === 0) button.classList.add("is-active")
      this.listTarget.appendChild(button)
    })
    this.activeIndex = matches.length ? 0 : -1
    this.listTarget.hidden = matches.length === 0
  }

  moveActive(delta) {
    const options = Array.from(this.listTarget.querySelectorAll(".font-combobox__option"))
    if (!options.length) return
    this.activeIndex = (this.activeIndex + delta + options.length) % options.length
    options.forEach((option, index) => option.classList.toggle("is-active", index === this.activeIndex))
    options[this.activeIndex].scrollIntoView({ block: "nearest" })
  }

  apply(family) {
    this.inputTarget.value = family
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.hide()
  }

  hide() {
    this.listTarget.hidden = true
    this.activeIndex = -1
  }

  parseCatalog() {
    const node = document.getElementById("cvgen-google-fonts")
    if (!node) return []
    try {
      return JSON.parse(node.textContent)
    } catch {
      return []
    }
  }

  score(family, query) {
    const name = family.toLowerCase()
    if (name === query) return 0
    if (name.startsWith(query)) return 1
    return 2 + name.indexOf(query)
  }
}
