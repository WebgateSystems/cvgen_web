# frozen_string_literal: true

class AppIdService
  class << self
    def version
      @version ||= read_hash
    end

    private

    def read_hash
      revision_file = Rails.root.join("REVISION")
      if File.exist?(revision_file)
        File.read(revision_file).strip.first(8)
      else
        `git -C #{Rails.root} rev-parse --short=8 HEAD`.chomp
      end
    end
  end
end
