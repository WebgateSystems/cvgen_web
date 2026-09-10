import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "cvgen-theme"

// Applies light / dark / system (default) via Bootstrap data-bs-theme.
export default class extends Controller {
  static targets = ["label"]

  connect() {
    this.apply(this.storedPreference())
    this.media = window.matchMedia("(prefers-color-scheme: dark)")
    this.mediaListener = () => {
      if (this.storedPreference() === "system") this.apply("system")
    }
    this.media.addEventListener("change", this.mediaListener)
  }

  disconnect() {
    this.media?.removeEventListener("change", this.mediaListener)
  }

  system(event) {
    event.preventDefault()
    this.persistAndApply("system")
  }

  light(event) {
    event.preventDefault()
    this.persistAndApply("light")
  }

  dark(event) {
    event.preventDefault()
    this.persistAndApply("dark")
  }

  persistAndApply(preference) {
    localStorage.setItem(STORAGE_KEY, preference)
    this.apply(preference)
  }

  storedPreference() {
    return localStorage.getItem(STORAGE_KEY) || "system"
  }

  resolve(preference) {
    if (preference === "light" || preference === "dark") return preference
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }

  apply(preference) {
    const resolved = this.resolve(preference)
    document.documentElement.dataset.bsTheme = resolved
    document.documentElement.dataset.themePreference = preference
    if (this.hasLabelTarget) {
      const labels = {
        system: this.element.dataset.labelSystem,
        light: this.element.dataset.labelLight,
        dark: this.element.dataset.labelDark
      }
      this.labelTarget.textContent = labels[preference] || preference
    }
  }
}
