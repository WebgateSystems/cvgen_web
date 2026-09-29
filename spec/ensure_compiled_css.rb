# frozen_string_literal: true

# Propshaft looks up stylesheet_link_tag "application" in app/assets/builds.
# That file is gitignored and produced by `yarn build:css`. Build it (or stub
# it) before Rails boots so request specs do not raise MissingAssetError.
require "fileutils"

root = File.expand_path("..", __dir__)
css = File.join(root, "app/assets/builds", "application.css")

unless File.file?(css) && File.size(css).positive?
  Dir.chdir(root) { system("yarn", "build:css") }
end

unless File.file?(css) && File.size(css).positive?
  FileUtils.mkdir_p(File.dirname(css))
  File.write(css, "/* rspec stub — run `yarn build:css` for real Bootstrap */\n")
end
