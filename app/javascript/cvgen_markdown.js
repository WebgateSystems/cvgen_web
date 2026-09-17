const FRONT_KEYS = [ "name", "headline", "email", "location" ]

export function emptyFront() {
  return { name: "", headline: "", email: "", location: "", phones: [], links: [] }
}

export function parseDocument(markdown) {
  const text = String(markdown ?? "").replace(/\r\n/g, "\n")
  if (!text.startsWith("---")) {
    return { front: emptyFront(), body: text }
  }

  const parts = text.split(/^---\s*$/m)
  if (parts.length < 3) {
    return { front: emptyFront(), body: text }
  }

  return {
    front: parseFront(parts[1]),
    body: parts.slice(2).join("---").replace(/^\n+/, "")
  }
}

export function serializeDocument(front, body) {
  const trimmed = String(body ?? "").replace(/^\n+/, "").replace(/\n+$/, "")
  return `${dumpFront(front)}\n\n${trimmed}\n`
}

export function bodyToHtml(markdown, tagsPlaceholder) {
  return parseBody(markdown).map((block) => renderBlock(block, tagsPlaceholder)).join("")
}

export function htmlToBody(root) {
  if (!root) return ""

  const parts = []
  root.childNodes.forEach((node) => {
    const chunk = serializeNode(node)
    if (chunk) parts.push(chunk)
  })
  return parts.join("\n\n").replace(/\n{3,}/g, "\n\n")
}

function parseFront(yaml) {
  const front = emptyFront()
  const lines = String(yaml ?? "").replace(/\r\n/g, "\n").split("\n")
  let currentList = null
  let currentItem = null

  const flushItem = () => {
    if (!currentList || !currentItem) return
    if (currentList === "phones") {
      const row = phoneFrom(currentItem)
      if (row) front.phones.push(row)
    } else if (currentList === "links") {
      const row = linkFrom(currentItem)
      if (row) front.links.push(row)
    }
    currentItem = null
  }

  lines.forEach((raw) => {
    const indent = (raw.match(/^ */)?.[0] || "").length
    const trimmed = raw.trim()
    if (!trimmed || trimmed.startsWith("#")) return

    const pair = trimmed.match(/^([\w-]+):\s*(.*)$/)
    const dash = trimmed.match(/^- (.*)$/)

    if (indent === 0 && pair && (pair[1] === "phones" || pair[1] === "links") && pair[2] === "") {
      flushItem()
      currentList = pair[1]
      currentItem = null
      return
    }

    if (currentList && indent > 0 && dash) {
      flushItem()
      currentItem = parseDashItem(dash[1])
      return
    }

    if (currentList && indent > 0 && pair && currentItem) {
      currentItem[pair[1]] = unquote(pair[2])
      return
    }

    flushItem()
    currentList = null
    if (indent === 0 && pair) {
      const key = pair[1]
      const value = unquote(pair[2])
      if (FRONT_KEYS.includes(key)) front[key] = value
    }
  })
  flushItem()
  return front
}

function parseDashItem(rest) {
  if (rest.includes(":") && !rest.startsWith("http://") && !rest.startsWith("https://")) {
    const index = rest.indexOf(":")
    const key = rest.slice(0, index).trim()
    const value = unquote(rest.slice(index + 1))
    if (/^[\w-]+$/.test(key)) return { [key]: value }
  }
  return { _string: unquote(rest) }
}

function phoneFrom(item) {
  if (item._string) return { label: "Phone", number: item._string }
  const number = item.number || item.phone || item.value || ""
  if (!number) return null
  return { label: item.label || "Phone", number }
}

function linkFrom(item) {
  if (item._string) return { label: item._string, url: item._string }
  const url = item.url || item.href || ""
  if (!url) return null
  return { label: item.label || url, url }
}

function dumpFront(front) {
  const lines = [ "---" ]
  FRONT_KEYS.forEach((key) => {
    if (front[key]) lines.push(`${key}: ${yamlScalar(front[key])}`)
  })
  dumpList(lines, "phones", front.phones || [], [ "label", "number" ])
  dumpList(lines, "links", front.links || [], [ "label", "url" ])
  lines.push("---")
  return lines.join("\n")
}

function dumpList(lines, key, rows, fields) {
  if (!rows.length) return
  lines.push(`${key}:`)
  rows.forEach((row) => {
    fields.forEach((field, index) => {
      const prefix = index === 0 ? "  - " : "    "
      lines.push(`${prefix}${field}: ${yamlScalar(row[field] || "")}`)
    })
  })
}

function yamlScalar(value) {
  const text = String(value ?? "")
  if (text === "") return '""'
  if (/[:#{}[\],&*?|<>=!%@`'"]/.test(text) || /^\s|\s$/.test(text) || /^(true|false|null|yes|no)$/i.test(text)) {
    return JSON.stringify(text)
  }
  return text
}

function unquote(value) {
  const text = String(value ?? "").trim()
  if ((text.startsWith("\"") && text.endsWith("\"")) || (text.startsWith("'") && text.endsWith("'"))) {
    try {
      return JSON.parse(text.startsWith("'") ? `"${text.slice(1, -1).replace(/"/g, '\\"')}"` : text)
    } catch (_error) {
      return text.slice(1, -1)
    }
  }
  return text
}

function parseBody(markdown) {
  const lines = String(markdown ?? "").replace(/\r\n/g, "\n").split("\n")
  const blocks = []
  let index = 0

  while (index < lines.length) {
    const line = lines[index]
    if (line.startsWith("### ")) {
      blocks.push({ type: "h3", text: line.slice(4).trim() })
      index += 1
      continue
    }
    if (line.startsWith("## ")) {
      blocks.push({ type: "h2", text: line.slice(3).trim() })
      index += 1
      continue
    }
    if (line.startsWith("# ")) {
      blocks.push({ type: "h1", text: line.slice(2).trim() })
      index += 1
      continue
    }
    if (/^\s*[-*] /.test(line)) {
      const items = []
      while (index < lines.length) {
        const current = lines[index]
        const item = current.match(/^\s*[-*] (.*)$/)
        const tags = current.match(/^\s+<!--\s*tags:\s*(.*?)\s*-->\s*$/)
        if (item) {
          items.push({ text: item[1].trim(), tags: "" })
          index += 1
        } else if (tags && items.length) {
          items[items.length - 1].tags = tags[1].trim()
          index += 1
        } else {
          break
        }
      }
      blocks.push({ type: "ul", items })
      continue
    }
    if (/^\s*\d+\. /.test(line)) {
      const items = []
      while (index < lines.length) {
        const item = lines[index].match(/^\s*\d+\. (.*)$/)
        if (item) {
          items.push({ text: item[1].trim() })
          index += 1
        } else {
          break
        }
      }
      blocks.push({ type: "ol", items })
      continue
    }
    if (line.trim() === "") {
      index += 1
      continue
    }

    const paragraph = [ line ]
    index += 1
    while (index < lines.length && lines[index].trim() !== "" && !/^(#{1,3} |\s*[-*] |\s*\d+\. )/.test(lines[index])) {
      paragraph.push(lines[index])
      index += 1
    }
    blocks.push({ type: "p", text: paragraph.join("\n").trim() })
  }

  return blocks
}

function renderBlock(block, tagsPlaceholder) {
  if (block.type === "h1") return `<h1>${inlineHtml(block.text)}</h1>`
  if (block.type === "h2") return `<h2>${inlineHtml(block.text)}</h2>`
  if (block.type === "h3") return `<h3>${inlineHtml(block.text)}</h3>`
  if (block.type === "ul") {
    const items = block.items.map((item) => {
      const tags = item.tags
        ? `<span class="md-tags">${escapeHtml(item.tags)}</span>`
        : `<span class="md-tags md-tags--empty" data-placeholder="${escapeHtml(tagsPlaceholder || "tags")}"></span>`
      return `<li><span class="md-item-text">${inlineHtml(item.text)}</span>${tags}</li>`
    }).join("")
    return `<ul>${items}</ul>`
  }
  if (block.type === "ol") {
    const items = block.items.map((item) => `<li><span class="md-item-text">${inlineHtml(item.text)}</span></li>`).join("")
    return `<ol>${items}</ol>`
  }
  if (/^https?:\/\//.test(block.text)) {
    return `<p class="md-url"><a href="${escapeHtml(block.text)}">${escapeHtml(block.text)}</a></p>`
  }
  return `<p>${inlineHtml(block.text).replace(/\n/g, "<br>")}</p>`
}

function inlineHtml(text) {
  let html = escapeHtml(text)
  html = html.replace(/\[([^\]]+)\]\((https?:[^)\s]+)\)/g, '<a href="$2">$1</a>')
  html = html.replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
  html = html.replace(/(^|[^*])\*(?!\*)([^*]+)\*(?!\*)/g, "$1<em>$2</em>")
  return html
}

function serializeNode(node) {
  if (node.nodeType === Node.TEXT_NODE) {
    return node.textContent
  }
  if (node.nodeType !== Node.ELEMENT_NODE) return ""

  const tag = node.tagName.toLowerCase()
  if (tag === "h1") return `# ${serializeInline(node)}`
  if (tag === "h2") return `## ${serializeInline(node)}`
  if (tag === "h3") return `### ${serializeInline(node)}`
  if (tag === "p") return serializeInline(node).replace(/\n+/g, "\n").trim()
  if (tag === "div") {
    if (node.classList?.contains("md-front") || node.classList?.contains("md-doc__head")) return ""
    const nested = serializeChildren(node)
    if (nested) return nested
    return serializeInline(node).trim()
  }
  if (tag === "ul") {
    return Array.from(node.children)
      .filter((child) => child.tagName === "LI")
      .map((item) => serializeLi(item, "-"))
      .join("\n")
  }
  if (tag === "ol") {
    return Array.from(node.children)
      .filter((child) => child.tagName === "LI")
      .map((item, index) => serializeLi(item, `${index + 1}.`))
      .join("\n")
  }
  if (tag === "li") return serializeLi(node, "-")
  if (tag === "br") return "\n"
  return serializeInline(node)
}

function serializeInline(node) {
  if (node.nodeType === Node.TEXT_NODE) return node.textContent
  if (node.nodeType !== Node.ELEMENT_NODE) return ""

  const tag = node.tagName.toLowerCase()
  if (tag === "br") return "\n"
  if (tag === "span" && node.classList.contains("md-tags")) return ""

  const inner = Array.from(node.childNodes).map(serializeInline).join("")
  if (tag === "strong" || tag === "b") return `**${inner}**`
  if (tag === "em" || tag === "i") return `*${inner}*`
  if (tag === "a") {
    const href = node.getAttribute("href") || ""
    return href ? `[${inner}](${href})` : inner
  }
  return inner
}

function serializeChildren(node) {
  const blocks = Array.from(node.childNodes).map(serializeNode).filter((chunk) => chunk && String(chunk).trim())
  if (!blocks.length) return ""
  if (blocks.length === 1) return blocks[0]
  return blocks.join("\n\n")
}

function serializeLi(li, marker) {
  const tagsEl = li.querySelector(":scope > .md-tags")
  const textEl = li.querySelector(":scope > .md-item-text")
  const text = (textEl ? serializeInline(textEl) : serializeInline(cloneWithoutTags(li))).replace(/\s+/g, " ").trim()
  const tags = tagsEl ? tagsEl.textContent.trim() : ""
  if (!text) return ""
  return tags ? `${marker} ${text}\n  <!-- tags: ${tags} -->` : `${marker} ${text}`
}

function cloneWithoutTags(li) {
  const clone = li.cloneNode(true)
  clone.querySelectorAll(".md-tags").forEach((el) => el.remove())
  return clone
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
}
