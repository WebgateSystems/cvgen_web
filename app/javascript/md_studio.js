function bindMdStudio(root) {
  if (!root || root.dataset.mdBound === "1") return
  root.dataset.mdBound = "1"

  const source = root.querySelector("[data-md-source]")
  const wysiwyg = root.querySelector("[data-md-wysiwyg]")
  const split = root.querySelector(".md-split")
  const gutter = root.querySelector(".md-split__gutter")
  const leftPane = root.querySelector(".md-split__source")
  const tagsPlaceholder = root.dataset.mdTags || "tags"
  const linkPrompt = root.dataset.mdLinkPrompt || "URL"
  let syncing = false
  let sourceTimer = null
  let wysiwygTimer = null

  function field(name) {
    return root.querySelector(`[data-md-field="${name}"]`)
  }

  function applyLayout() {
    if (!split) return
    split.style.display = "flex"
    split.style.flexDirection = "row"
    split.style.alignItems = "stretch"
    split.style.width = "100%"
    split.style.height = "calc(100vh - 11rem)"
    split.style.minHeight = "32rem"
    split.querySelectorAll(".md-split__pane").forEach((pane) => {
      pane.style.display = "flex"
      pane.style.flexDirection = "column"
      pane.style.flex = "1 1 50%"
      pane.style.width = "50%"
      pane.style.minWidth = "0"
      pane.style.minHeight = "0"
      pane.style.height = "100%"
      pane.style.overflow = "hidden"
    })
    if (source) {
      source.style.flex = "1 1 auto"
      source.style.width = "100%"
      source.style.minHeight = "0"
      source.style.height = "100%"
      source.style.border = "0"
      source.style.resize = "none"
      source.style.boxSizing = "border-box"
    }
    const doc = split.querySelector(".md-doc")
    if (doc) {
      doc.style.flex = "1 1 auto"
      doc.style.minHeight = "0"
      doc.style.height = "100%"
      doc.style.overflow = "auto"
    }
  }

  function fillFront(front) {
    const data = front || emptyFront()
    const name = field("name")
    const headline = field("headline")
    const email = field("email")
    const location = field("location")
    if (name) name.value = data.name || ""
    if (headline) headline.value = data.headline || ""
    if (email) email.value = data.email || ""
    if (location) location.value = data.location || ""
    replacePairs(root.querySelector("[data-md-phones]"), root.querySelector("[data-md-phone-template]"), data.phones, [ "label", "number" ])
    replacePairs(root.querySelector("[data-md-links]"), root.querySelector("[data-md-link-template]"), data.links, [ "label", "url" ])
  }

  function readFront() {
    return {
      name: field("name")?.value.trim() || "",
      headline: field("headline")?.value.trim() || "",
      email: field("email")?.value.trim() || "",
      location: field("location")?.value.trim() || "",
      phones: readPairs(root.querySelector("[data-md-phones]"), [ "label", "number" ]).filter((row) => row.number),
      links: readPairs(root.querySelector("[data-md-links]"), [ "label", "url" ]).filter((row) => row.url)
    }
  }

  function replacePairs(container, template, rows, keys) {
    if (!container || !template) return
    container.innerHTML = ""
    ;(rows || []).forEach((row) => {
      const node = template.content.cloneNode(true)
      keys.forEach((key) => {
        const input = node.querySelector(`[data-key="${key}"]`)
        if (input) input.value = row[key] || ""
      })
      container.appendChild(node)
    })
  }

  function readPairs(container, keys) {
    if (!container) return []
    return Array.from(container.querySelectorAll(".md-pair")).map((row) => {
      const item = {}
      keys.forEach((key) => {
        item[key] = row.querySelector(`[data-key="${key}"]`)?.value.trim() || ""
      })
      return item
    }).filter((item) => keys.some((key) => item[key]))
  }

  function renderFromSource() {
    if (!source || !wysiwyg) return
    const doc = parseDocument(source.value)
    syncing = true
    fillFront(doc.front)
    wysiwyg.innerHTML = bodyToHtml(doc.body, tagsPlaceholder) || "<p><br></p>"
    syncing = false
  }

  function writeSource() {
    if (!source || !wysiwyg) return
    syncing = true
    source.value = serializeDocument(readFront(), htmlToBody(wysiwyg))
    syncing = false
  }

  function onSourceInput() {
    if (syncing) return
    clearTimeout(sourceTimer)
    sourceTimer = setTimeout(renderFromSource, 50)
  }

  function onWysiwygInput() {
    if (syncing) return
    clearTimeout(wysiwygTimer)
    wysiwygTimer = setTimeout(writeSource, 50)
  }

  applyLayout()
  renderFromSource()

  source?.addEventListener("input", onSourceInput)
  wysiwyg?.addEventListener("input", onWysiwygInput)
  wysiwyg?.addEventListener("keyup", onWysiwygInput)
  wysiwyg?.addEventListener("keydown", (event) => {
    const meta = event.metaKey || event.ctrlKey
    if (!meta) return
    const key = event.key.toLowerCase()
    if (key === "b") {
      event.preventDefault()
      document.execCommand("bold", false, null)
      onWysiwygInput()
    } else if (key === "i") {
      event.preventDefault()
      document.execCommand("italic", false, null)
      onWysiwygInput()
    }
  })

  root.addEventListener("input", (event) => {
    if (event.target.closest("[data-md-field], [data-md-phones], [data-md-links]")) onWysiwygInput()
  })

  root.addEventListener("click", (event) => {
    const addPhone = event.target.closest("[data-md-add-phone]")
    const addLink = event.target.closest("[data-md-add-link]")
    const remove = event.target.closest("[data-md-remove]")
    if (addPhone) {
      event.preventDefault()
      const template = root.querySelector("[data-md-phone-template]")
      root.querySelector("[data-md-phones]")?.appendChild(template.content.cloneNode(true))
      writeSource()
    } else if (addLink) {
      event.preventDefault()
      const template = root.querySelector("[data-md-link-template]")
      root.querySelector("[data-md-links]")?.appendChild(template.content.cloneNode(true))
      writeSource()
    } else if (remove) {
      event.preventDefault()
      remove.closest(".md-pair")?.remove()
      writeSource()
    }
  })

  root.addEventListener("mousedown", (event) => {
    const button = event.target.closest("[data-md-cmd]")
    if (!button || !wysiwyg) return
    event.preventDefault()
    wysiwyg.focus()
    const command = button.getAttribute("data-md-cmd")
    if (command === "createLink") {
      const url = window.prompt(linkPrompt, "https://")
      if (url) document.execCommand("createLink", false, url)
    } else if (command === "h1" || command === "h2" || command === "h3") {
      if (!document.execCommand("formatBlock", false, command)) {
        document.execCommand("formatBlock", false, `<${command}>`)
      }
    } else {
      document.execCommand(command, false, null)
    }
    onWysiwygInput()
  })

  if (gutter && leftPane && split) {
    gutter.addEventListener("pointerdown", (event) => {
      event.preventDefault()
      const rect = split.getBoundingClientRect()
      const move = (moveEvent) => {
        const ratio = (moveEvent.clientX - rect.left) / rect.width
        const percent = Math.min(75, Math.max(25, ratio * 100))
        leftPane.style.flex = `1 1 ${percent}%`
        leftPane.style.width = `${percent}%`
        const right = split.querySelector(".md-split__wysiwyg")
        if (right) {
          right.style.flex = `1 1 ${100 - percent}%`
          right.style.width = `${100 - percent}%`
        }
      }
      const up = () => {
        window.removeEventListener("pointermove", move)
        window.removeEventListener("pointerup", up)
        document.body.style.cursor = ""
        document.body.style.userSelect = ""
      }
      document.body.style.cursor = "col-resize"
      document.body.style.userSelect = "none"
      window.addEventListener("pointermove", move)
      window.addEventListener("pointerup", up)
    })
  }
}

function startMdStudio() {
  document.querySelectorAll("[data-md-studio]").forEach(bindMdStudio)
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", startMdStudio)
} else {
  startMdStudio()
}
document.addEventListener("turbo:load", startMdStudio)
document.addEventListener("turbo:render", startMdStudio)
