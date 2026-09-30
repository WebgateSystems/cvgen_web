import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "list", "template", "body", "confirm", "confirmBody", "cancel", "add" ]
  static values = { confirmMessage: String }

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", Date.now().toString())
    this.listTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-offer-sections-target='row']")
    if (!row) return

    this.pendingRow = row
    this.fillConfirm(this.sectionName(row))
    this.confirmTarget.showModal()
    this.cancelTarget.focus()
  }

  confirmRemove(event) {
    event.preventDefault()
    const row = this.pendingRow
    this.pendingRow = null
    row?.remove()
    this.confirmTarget.close()
    this.addTarget.focus()
  }

  cancelRemove(event) {
    event?.preventDefault()
    this.pendingRow = null
    if (this.confirmTarget.open) this.confirmTarget.close()
  }

  dismiss() {
    this.pendingRow = null
  }

  backdrop(event) {
    if (event.target !== this.confirmTarget) return

    this.confirmTarget.close()
    this.dismiss()
  }

  bodyTargetConnected(element) {
    this.fit(element)
  }

  fitBody(event) {
    this.fit(event.target)
  }

  fit(element) {
    element.style.height = "auto"
    element.style.height = `${element.scrollHeight}px`
  }

  kindChanged(event) {
    const row = event.target.closest("[data-offer-sections-target='row']")
    const title = row?.querySelector("[data-offer-sections-target='title']")
    if (!title) return

    const custom = event.target.value === "custom"
    title.hidden = !custom
    if (!custom) title.value = ""
    if (custom) title.focus()
  }

  sectionName(row) {
    const select = row.querySelector("[data-offer-sections-target='kind']")
    const title = row.querySelector("[data-offer-sections-target='title']")
    const typed = title && !title.hidden ? title.value.trim() : ""
    if (typed) return typed

    return select?.selectedOptions?.[0]?.textContent.trim() || ""
  }

  fillConfirm(name) {
    const [ before, after = "" ] = this.confirmMessageValue.split("%{name}")
    const strong = document.createElement("strong")
    strong.textContent = name
    this.confirmBodyTarget.replaceChildren(document.createTextNode(before), strong, document.createTextNode(after))
  }
}
