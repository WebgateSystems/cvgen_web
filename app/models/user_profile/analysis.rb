# frozen_string_literal: true

class UserProfile::Analysis
  STRING_KEYS = %w[person_name headline summary].freeze
  LIST_KEYS = %w[skills strengths gaps].freeze
  EXPERIENCE_KEYS = %w[company role from to].freeze
  EDUCATION_KEYS = %w[school degree year].freeze
  LANGUAGE_KEYS = %w[name level].freeze
  CONTACT_STRING_KEYS = %w[email location].freeze
  PHONE_KEYS = %w[label number].freeze
  LINK_KEYS = %w[label url].freeze
  LINK_ALIASES = {
    "linkedin" => "LinkedIn",
    "github" => "GitHub",
    "website" => "Website",
    "portfolio" => "Portfolio"
  }.freeze
  FORM_LIST_KEYS = LIST_KEYS.index_with { |key| "#{key}_text" }.freeze

  class << self
    def blank
      {
        "person_name" => "",
        "headline" => "",
        "summary" => "",
        "contact" => blank_contact,
        "skills" => [],
        "languages" => [],
        "experience" => [],
        "education" => [],
        "strengths" => [],
        "gaps" => []
      }
    end

    def blank_contact
      { "email" => "", "location" => "", "phones" => [], "links" => [] }
    end

    def blank_phone
      { "label" => "", "number" => "" }
    end

    def blank_link
      { "label" => "", "url" => "" }
    end

    def blank_experience
      { "company" => "", "role" => "", "from" => "", "to" => "", "highlights" => [] }
    end

    def blank_education
      { "school" => "", "degree" => "", "year" => "" }
    end

    def blank_language
      { "name" => "", "level" => "" }
    end

    def normalize(raw)
      hash = stringify(raw)
      blank
        .merge(STRING_KEYS.index_with { |key| hash[key].to_s.strip })
        .merge(LIST_KEYS.index_with { |key| lines(hash[key]) })
        .merge(
          "contact" => normalize_contact(hash),
          "languages" => compact_languages(hash["languages"].presence || hash["languages_text"]),
          "experience" => compact_experience(rows(hash["experience"])),
          "education" => compact_education(rows(hash["education"]))
        )
    end

    def from_form(params)
      hash = stringify(params)
      FORM_LIST_KEYS.each do |key, text_key|
        hash[key] = lines(hash.delete(text_key) || hash[key])
      end
      if hash.key?("languages_text")
        text = hash.delete("languages_text")
        hash["languages"] = text if hash["languages"].blank?
      end
      rows(hash["experience"]).each do |row|
        next unless row.is_a?(Hash)

        row["highlights"] = lines(row.delete("highlights_text") || row["highlights"])
      end
      normalize(hash)
    end

    def list_text(values)
      Array(values).map { |value| value.to_s.strip }.reject(&:blank?).join("\n")
    end

    def language_line(row)
      data = stringify(row)
      name = data["name"].presence || row.to_s.strip
      level = data["level"].to_s.strip
      return name if level.blank?

      "#{name} (#{level})"
    end

    private

    def stringify(raw)
      case raw
      when ActionController::Parameters then raw.to_unsafe_h.deep_stringify_keys
      when Hash then raw.deep_stringify_keys
      else {}
      end
    end

    def rows(value)
      case value
      when Hash then value.keys.sort_by(&:to_i).filter_map { |key| value[key] }
      when Array then value
      else []
      end
    end

    def lines(value)
      Array(value).flat_map { |entry| entry.to_s.split(/\r?\n/) }.map(&:strip).reject(&:blank?)
    end

    def normalize_contact(hash)
      nested = stringify(hash["contact"])
      blank_contact.merge(
        "email" => (nested["email"].presence || hash["email"]).to_s.strip,
        "location" => (nested["location"].presence || hash["location"]).to_s.strip,
        "phones" => compact_phones(nested["phones"].presence || hash["phones"] || hash["phone"]),
        "links" => compact_links(
          Array(rows(nested["links"].presence || hash["links"])) + aliased_links(hash, nested)
        )
      )
    end

    def compact_phones(value)
      entries = case value
      when String then [ { "number" => value } ]
      else rows(value)
      end
      entries.filter_map { |row| phone_row(row) }
        .uniq { |row| row["number"].delete(" ") }
    end

    def compact_links(entries)
      entries.filter_map { |row| link_row(row) }
        .uniq { |row| row["url"].downcase }
    end

    def aliased_links(hash, nested)
      LINK_ALIASES.filter_map do |key, label|
        url = nested[key].presence || hash[key]
        next if url.blank?

        { "label" => label, "url" => url.to_s.strip }
      end
    end

    def phone_row(row)
      data = stringify(row)
      record = blank_phone.merge(PHONE_KEYS.index_with { |key| data[key].to_s.strip })
      record["number"] = data["phone"].to_s.strip if record["number"].blank?
      record if record["number"].present?
    end

    def link_row(row)
      data = stringify(row)
      record = blank_link.merge(LINK_KEYS.index_with { |key| data[key].to_s.strip })
      record["label"] = record["url"] if record["label"].blank? && record["url"].present?
      record if record["url"].present?
    end

    def compact_languages(value)
      entries = case value
      when String then lines(value)
      else rows(value)
      end
      entries.filter_map { |row| language_row(row) }
        .uniq { |row| row["name"].downcase }
    end

    def language_row(row)
      if row.is_a?(String)
        name, level = parse_language_line(row)
        return blank_language.merge("name" => name, "level" => level) if name.present?
      end

      data = stringify(row)
      record = blank_language.merge(LANGUAGE_KEYS.index_with { |key| data[key].to_s.strip })
      record["name"] = data["language"].to_s.strip if record["name"].blank?
      if record["name"].blank?
        name, parsed_level = parse_language_line(data["text"].presence || row.to_s)
        record["name"] = name
        record["level"] = parsed_level if record["level"].blank?
      end
      record if record["name"].present?
    end

    def parse_language_line(line)
      text = line.to_s.strip
      if (match = text.match(/\A(.+?)\s*\((.+)\)\s*\z/))
        return [ match[1].strip, match[2].strip ]
      end
      if (match = text.match(/\A(.+?)\s+[—–:]\s+(.+)\z/))
        return [ match[1].strip, match[2].strip ]
      end
      if (match = text.match(/\A(.+?)\s+-\s+(.+)\z/))
        return [ match[1].strip, match[2].strip ]
      end

      [ text, "" ]
    end

    def compact_experience(entries)
      entries.filter_map { |row| experience_row(row) }
    end

    def compact_education(entries)
      entries.filter_map { |row| education_row(row) }
    end

    def experience_row(row)
      data = stringify(row)
      record = blank_experience
        .merge(EXPERIENCE_KEYS.index_with { |key| data[key].to_s.strip })
        .merge("highlights" => lines(data["highlights"]))
      record if EXPERIENCE_KEYS.any? { |key| record[key].present? } || record["highlights"].any?
    end

    def education_row(row)
      data = stringify(row)
      record = blank_education.merge(EDUCATION_KEYS.index_with { |key| data[key].to_s.strip })
      record if record.values.any?(&:present?)
    end
  end
end
