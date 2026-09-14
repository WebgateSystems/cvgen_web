import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "query", "rows", "sentinel", "empty" ]
  static values = {
    page: { type: Number, default: 1 },
    hasMore: { type: Boolean, default: false },
    status: String
  }

  connect() {
    this.activeQuery = this.currentQuery()
    this.observe()
  }

  disconnect() {
    this.observer?.disconnect()
    clearTimeout(this.searchTimer)
  }

  search() {
    const query = this.hasQueryTarget ? this.queryTarget.value.trim() : ""
    clearTimeout(this.searchTimer)

    if (query.length > 0 && query.length < 3) {
      if (this.activeQuery) {
        this.searchTimer = setTimeout(() => {
          this.activeQuery = ""
          this.reload()
        }, 250)
      }
      return
    }

    this.searchTimer = setTimeout(() => {
      this.activeQuery = query
      this.reload()
    }, 250)
  }

  async reload() {
    this.pageValue = 1
    this.hasMoreValue = true
    const html = await this.fetchPage(1)
    if (html === null) return

    this.rowsTarget.innerHTML = html
    this.toggleEmpty()
    this.dispatch("loaded")
    this.replaceUrl()
    this.observe()
  }

  async loadMore() {
    if (!this.hasMoreValue || this.loading) return

    this.loading = true
    const nextPage = this.pageValue + 1
    const html = await this.fetchPage(nextPage)
    this.loading = false
    if (html === null) return

    this.pageValue = nextPage
    this.rowsTarget.insertAdjacentHTML("beforeend", html)
    this.dispatch("loaded")
    this.observe()
  }

  async fetchPage(page) {
    const url = this.buildUrl({ page, rows: true })
    const response = await fetch(url, {
      headers: {
        Accept: "text/html",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    if (!response.ok) return null

    this.hasMoreValue = response.headers.get("X-Has-More") === "1"
    return response.text()
  }

  observe() {
    this.observer?.disconnect()
    if (!this.hasMoreValue || !this.hasSentinelTarget) return

    this.observer = new IntersectionObserver((entries) => {
      if (entries.some((entry) => entry.isIntersecting)) this.loadMore()
    }, { rootMargin: "240px" })
    this.observer.observe(this.sentinelTarget)
  }

  toggleEmpty() {
    if (!this.hasEmptyTarget) return

    this.emptyTarget.hidden = this.rowsTarget.querySelector("tr") !== null
  }

  replaceUrl() {
    history.replaceState(history.state, "", this.buildUrl({ page: 1, rows: false }))
  }

  buildUrl({ page, rows }) {
    const url = new URL(this.element.dataset.listUrl || window.location.pathname, window.location.origin)
    const query = this.currentQuery()
    const status = this.statusValue

    if (query.length >= 3) url.searchParams.set("q", query)
    if (status) url.searchParams.set("status", status)
    if (rows) {
      url.searchParams.set("rows", "1")
      url.searchParams.set("page", String(page))
    }
    return url
  }

  currentQuery() {
    if (!this.hasQueryTarget) return ""

    const query = this.queryTarget.value.trim()
    return query.length >= 3 ? query : ""
  }
}
