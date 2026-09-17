# frozen_string_literal: true

module UploadHelpers
  def markdown_upload(path = Rails.root.join("spec/fixtures/files/cv-sample.md"))
    Rack::Test::UploadedFile.new(path.to_s, "text/markdown")
  end

  def theme_upload(path = Cvgen::ROOT.join("themes/modern-blue.yaml"))
    Rack::Test::UploadedFile.new(path.to_s, "text/yaml")
  end

  def invalid_markdown_upload
    file = Tempfile.new([ "bad", ".md" ])
    file.write("this is not a cvgen document\n")
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "text/markdown")
  end

  def cv_text_upload(content, name: "cv.txt")
    io = StringIO.new(content)
    Rack::Test::UploadedFile.new(io, "text/plain", original_filename: name)
  end
end

RSpec.configure do |config|
  config.include UploadHelpers
end
