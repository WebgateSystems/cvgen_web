import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    document.body.classList.add("cv-modal-open")
    this.panel?.focus()
  }

  disconnect() {
    document.body.classList.remove("cv-modal-open")
  }

  close(event) {
    event?.preventDefault()
    this.clear()
  }

  keydown(event) {
    if (event.key === "Escape") this.clear()
  }

  clear() {
    const frame = this.element.closest("turbo-frame")
    if (!frame) return

    frame.removeAttribute("src")
    frame.innerHTML = ""
  }

  get panel() {
    return this.element.querySelector(".cv-modal__panel")
  }
}
