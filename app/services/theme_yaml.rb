# frozen_string_literal: true

class ThemeYaml
  def self.patch(yaml, name: nil, heading: nil, body: nil)
    text = yaml.to_s.dup
    text = set_top_level(text, "name", name) if name.present?
    text = set_indented(text, "heading", heading) if heading.present?
    text = set_indented(text, "body", body) if body.present?
    text
  end

  def self.scalar(yaml, key)
    match = yaml.to_s.match(/(?:^|\n)[ \t]*#{Regexp.escape(key)}:[ \t]*(?:"([^"]*)"|'([^']*)'|(\S[^\n]*))\s*(?=\n|\z)/)
    return if match.nil?

    (match[1] || match[2] || match[3]).to_s.strip
  end

  def self.set_top_level(yaml, key, value)
    quoted = quote(value)
    pattern = /^#{Regexp.escape(key)}:[ \t]*.*$/
    return yaml unless yaml.match?(pattern)

    yaml.sub(pattern, "#{key}: #{quoted}")
  end

  def self.set_indented(yaml, key, value)
    quoted = quote(value)
    pattern = /^([ \t]*#{Regexp.escape(key)}:[ \t]*).*$/
    return yaml unless yaml.match?(pattern)

    yaml.sub(pattern, "\\1#{quoted}")
  end

  def self.quote(value)
    %("#{value.to_s.gsub('\\', '\\\\').gsub('"', '\\"')}")
  end
end
