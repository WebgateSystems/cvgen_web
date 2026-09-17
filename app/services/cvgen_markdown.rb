# frozen_string_literal: true

require "cgi"

class CvgenMarkdown
  def self.normalize(markdown)
    text = markdown.to_s
    return text unless text.start_with?("---")

    parts = text.split(/^---\s*$/, 3)
    return text unless parts.length >= 3

    front = YAML.safe_load(parts[1], permitted_classes: []) || {}
    front = stringify(front)
    phones = normalize_phones(front["phones"])
    links = normalize_links(front["links"])
    front["phones"] = phones
    front["links"] = links
    front.delete("phones") if phones.empty?
    front.delete("links") if links.empty?

    "#{front.to_yaml}---#{parts[2]}"
  rescue Psych::SyntaxError
    text
  end

  def self.stringify(value)
    case value
    when Hash then value.each_with_object({}) { |(key, item), hash| hash[key.to_s] = stringify(item) }
    when Array then value.map { |item| stringify(item) }
    else value
    end
  end

  def self.list(value)
    case value
    when nil then []
    when Array then value
    when Hash
      data = stringify(value)
      if data.key?("number") || data.key?("phone") || data.key?("url") || data.key?("label")
        [ data ]
      else
        data.keys.sort_by(&:to_s).map { |key| data[key] }
      end
    else
      [ value ]
    end
  end

  def self.normalize_phones(value)
    list(value).filter_map { |row| phone_row(row) }
  end

  def self.normalize_links(value)
    list(value).filter_map { |row| link_row(row) }
  end

  def self.phone_row(row)
    if row.is_a?(String)
      number = row.strip
      return { "label" => "Phone", "number" => number } if number.present?
    end

    data = stringify(row)
    return unless data.is_a?(Hash)

    number = data["number"].presence || data["phone"].presence || data["value"].to_s.strip
    return if number.blank?

    { "label" => data["label"].presence || "Phone", "number" => number }
  end

  def self.link_row(row)
    if row.is_a?(String)
      url = row.strip
      return { "label" => url, "url" => url } if url.present?
    end

    data = stringify(row)
    return unless data.is_a?(Hash)

    url = data["url"].presence || data["href"].to_s.strip
    return if url.blank?

    { "label" => data["label"].presence || url, "url" => url }
  end

  def self.split_document(markdown)
    text = markdown.to_s.gsub("\r\n", "\n")
    empty = { "name" => "", "headline" => "", "email" => "", "location" => "", "phones" => [], "links" => [] }
    unless text.start_with?("---")
      return [ empty, text ]
    end

    parts = text.split(/^---\s*$/, 3)
    unless parts.length >= 3
      return [ empty, text ]
    end

    front = empty.merge(stringify(YAML.safe_load(parts[1], permitted_classes: []) || {}))
    front["phones"] = normalize_phones(front["phones"])
    front["links"] = normalize_links(front["links"])
    [ front, parts[2].to_s.sub(/\A\n+/, "") ]
  rescue Psych::SyntaxError
    [ empty, text ]
  end

  def self.body_html(markdown, tags_placeholder: "tags")
    parse_body(markdown).map { |block| render_block(block, tags_placeholder) }.join
  end

  def self.parse_body(markdown)
    lines = markdown.to_s.gsub("\r\n", "\n").split("\n")
    blocks = []
    index = 0

    while index < lines.length
      line = lines[index]
      if line.start_with?("### ")
        blocks << { type: "h3", text: line[4..].strip }
        index += 1
      elsif line.start_with?("## ")
        blocks << { type: "h2", text: line[3..].strip }
        index += 1
      elsif line.start_with?("# ")
        blocks << { type: "h1", text: line[2..].strip }
        index += 1
      elsif line.match?(/\A\s*[-*] /)
        items = []
        while index < lines.length
          current = lines[index]
          item = current.match(/\A\s*[-*] (.*)\z/)
          tags = current.match(/\A\s+<!--\s*tags:\s*(.*?)\s*-->\s*\z/)
          if item
            items << { text: item[1].strip, tags: "" }
            index += 1
          elsif tags && items.any?
            items.last[:tags] = tags[1].strip
            index += 1
          else
            break
          end
        end
        blocks << { type: "ul", items: items }
      elsif line.blank?
        index += 1
      else
        paragraph = [ line ]
        index += 1
        while index < lines.length && lines[index].present? && !lines[index].match?(/\A(\#{1,3} |\s*[-*] )/)
          paragraph << lines[index]
          index += 1
        end
        blocks << { type: "p", text: paragraph.join("\n").strip }
      end
    end

    blocks
  end

  def self.render_block(block, tags_placeholder)
    case block[:type]
    when "h1" then "<h1>#{h(block[:text])}</h1>"
    when "h2" then "<h2>#{h(block[:text])}</h2>"
    when "h3" then "<h3>#{h(block[:text])}</h3>"
    when "ul"
      items = block[:items].map do |item|
        tags = if item[:tags].present?
          %(<span class="md-tags">#{h(item[:tags])}</span>)
        else
          %(<span class="md-tags md-tags--empty" data-placeholder="#{h(tags_placeholder)}"></span>)
        end
        %(<li><span class="md-item-text">#{h(item[:text])}</span>#{tags}</li>)
      end.join
      "<ul>#{items}</ul>"
    else
      text = block[:text].to_s
      if text.match?(%r{\Ahttps?://})
        %(<p class="md-url"><a href="#{h(text)}">#{h(text)}</a></p>)
      else
        "<p>#{h(text).gsub("\n", "<br>")}</p>"
      end
    end
  end

  def self.h(value)
    CGI.escapeHTML(value.to_s)
  end
end
