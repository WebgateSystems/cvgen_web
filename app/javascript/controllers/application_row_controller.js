import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  open(event) {
    if (event.target.closest("a, button, form, input, label")) return

    const frame = document.getElementById("application_modal")
    if (!frame || !this.urlValue) return

    frame.setAttribute("src", this.urlValue)
  }

  keydown(event) {
    if (event.key !== "Enter" && event.key !== " ") return
    event.preventDefault()
    this.open(event)
  }
}
