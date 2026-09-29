import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "list", "template" ]

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", Date.now().toString())
    this.listTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-company-identifiers-target='row']")
    if (!row) return

    const destroy = row.querySelector("input[name*='[_destroy]']")
    if (destroy) {
      destroy.value = "1"
      row.hidden = true
      return
    }

    row.remove()
  }
}
