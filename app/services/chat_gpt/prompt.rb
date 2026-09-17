# frozen_string_literal: true

class ChatGpt::Prompt
  class Missing < StandardError; end

  DIR = Rails.root.join("config/prompts")

  def self.load(name)
    path = DIR.join("#{name}.txt")
    raise Missing, "Missing prompt #{name.inspect} (#{path})" unless File.exist?(path)

    File.read(path).strip
  end
end
