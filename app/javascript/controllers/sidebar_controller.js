import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "cvgen-sidebar"
const COLLAPSED_CLASS = "sidebar-collapsed"

export default class extends Controller {
  static targets = [ "toggle", "icon" ]

  connect() {
    this.sync()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    this.apply(!this.collapsed)
  }

  apply(collapsed) {
    document.documentElement.removeAttribute("data-sidebar")
    document.documentElement.classList.toggle(COLLAPSED_CLASS, collapsed)
    localStorage.setItem(STORAGE_KEY, collapsed ? "collapsed" : "expanded")
    this.sync()
  }

  sync() {
    const collapsed = this.collapsed
    const label = collapsed
      ? this.element.dataset.labelExpand
      : this.element.dataset.labelCollapse

    this.toggleTargets.forEach((button) => {
      button.setAttribute("aria-expanded", collapsed ? "false" : "true")
      button.setAttribute("aria-label", label)
      button.setAttribute("title", label)
    })

    this.iconTargets.forEach((icon) => {
      icon.classList.remove("bi-chevron-double-left", "bi-chevron-double-right")
      icon.classList.add("bi", collapsed ? "bi-chevron-double-right" : "bi-chevron-double-left")
    })
  }

  get collapsed() {
    return document.documentElement.classList.contains(COLLAPSED_CLASS)
  }
}
