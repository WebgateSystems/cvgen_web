import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["table", "list", "item"]
  static values = {
    storageKey: { type: String, default: "cvgen-application-columns" },
    keys: Array,
    defaultVisible: Array
  }

  connect() {
    this.prefs = this.load()
    this.syncPicker()
    this.applyToTable()
  }

  toggle(event) {
    const key = event.currentTarget.closest("[data-column]")?.dataset.column
    if (!key) return

    const visible = new Set(this.prefs.visible)
    if (event.currentTarget.checked) {
      visible.add(key)
    } else {
      visible.delete(key)
      if (visible.size === 0) {
        event.currentTarget.checked = true
        return
      }
    }

    this.prefs.visible = this.prefs.order.filter((column) => visible.has(column))
    this.save()
    this.applyToTable()
  }

  reset(event) {
    event.preventDefault()
    this.prefs = this.normalized({
      order: this.keysValue,
      visible: this.defaultVisibleValue
    })
    this.save()
    this.syncPicker()
    this.applyToTable()
  }

  dragstart(event) {
    this.dragging = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", this.dragging.dataset.column)
    this.dragging.classList.add("is-dragging")
  }

  dragover(event) {
    event.preventDefault()
    const item = event.target.closest("[data-column]")
    if (!item || !this.dragging || item === this.dragging) return
    if (item.parentElement !== this.listTarget) return

    const items = [ ...this.listTarget.children ]
    const from = items.indexOf(this.dragging)
    const to = items.indexOf(item)
    if (from < to) {
      item.after(this.dragging)
    } else {
      item.before(this.dragging)
    }
  }

  drop(event) {
    event.preventDefault()
    this.commitOrder()
  }

  dragend() {
    this.dragging?.classList.remove("is-dragging")
    this.dragging = null
    this.commitOrder()
  }

  commitOrder() {
    const order = this.itemTargets.map((item) => item.dataset.column)
    const visible = new Set(this.prefs.visible)
    this.prefs.order = this.normalized({ order, visible: this.prefs.visible }).order
    this.prefs.visible = this.prefs.order.filter((column) => visible.has(column))
    this.save()
    this.applyToTable()
  }

  load() {
    try {
      return this.normalized(JSON.parse(localStorage.getItem(this.storageKeyValue) || "{}"))
    } catch {
      return this.normalized({})
    }
  }

  save() {
    localStorage.setItem(this.storageKeyValue, JSON.stringify(this.prefs))
  }

  normalized(raw) {
    const keys = this.keysValue
    const order = []
    ;(raw.order || []).forEach((key) => {
      if (keys.includes(key) && !order.includes(key)) order.push(key)
    })
    keys.forEach((key) => {
      if (!order.includes(key)) order.push(key)
    })

    const visibleSource = Array.isArray(raw.visible) ? raw.visible : this.defaultVisibleValue
    let visible = visibleSource.filter((key) => keys.includes(key))
    if (visible.length === 0) visible = [ ...this.defaultVisibleValue ]

    return { order, visible }
  }

  syncPicker() {
    if (!this.hasListTarget) return

    this.prefs.order.forEach((key) => {
      const item = this.itemTargets.find((node) => node.dataset.column === key)
      if (item) this.listTarget.append(item)
    })

    this.itemTargets.forEach((item) => {
      const checkbox = item.querySelector("input[type='checkbox']")
      if (checkbox) checkbox.checked = this.prefs.visible.includes(item.dataset.column)
    })
  }

  applyToTable() {
    if (!this.hasTableTarget) return

    this.tableTarget.querySelectorAll("tr").forEach((row) => {
      const cells = {}
      row.querySelectorAll("[data-column]").forEach((cell) => {
        cells[cell.dataset.column] = cell
      })

      this.prefs.order.forEach((key) => {
        const cell = cells[key]
        if (!cell) return
        cell.hidden = !this.prefs.visible.includes(key)
        row.append(cell)
      })

      if (cells.actions) row.append(cells.actions)
    })
  }
}
