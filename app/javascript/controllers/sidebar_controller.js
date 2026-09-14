import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "cvgen-sidebar"

export default class extends Controller {
  static targets = ["toggle", "icon"]

  connect() {
    this.sync()
  }

  toggle(event) {
    event.preventDefault()
    this.apply(document.documentElement.dataset.sidebar !== "collapsed")
  }

  apply(collapsed) {
    if (collapsed) {
      document.documentElement.dataset.sidebar = "collapsed"
      localStorage.setItem(STORAGE_KEY, "collapsed")
    } else {
      delete document.documentElement.dataset.sidebar
      localStorage.setItem(STORAGE_KEY, "expanded")
    }
    this.sync()
  }

  sync() {
    const collapsed = document.documentElement.dataset.sidebar === "collapsed"
    const label = collapsed
      ? this.element.dataset.labelExpand
      : this.element.dataset.labelCollapse

    this.toggleTargets.forEach((button) => {
      button.setAttribute("aria-expanded", collapsed ? "false" : "true")
      button.setAttribute("aria-label", label)
      button.setAttribute("title", label)
    })

    this.iconTargets.forEach((icon) => {
      icon.className = collapsed ? "bi bi-chevron-double-right" : "bi bi-chevron-double-left"
    })
  }
}
