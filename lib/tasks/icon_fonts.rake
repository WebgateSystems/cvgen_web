# frozen_string_literal: true

require "fileutils"

module IconFonts
  module_function

  def source_dir
    [
      Rails.root.join("public/fonts"),
      Rails.root.join("node_modules/bootstrap-icons/font/fonts")
    ].find { |dir| Dir[dir.join("bootstrap-icons.woff*")].any? }
  end

  def copy_to(*dests)
    src = source_dir
    return unless src

    dests.flatten.each do |dest|
      dest = Pathname(dest)
      next if dest.directory? && src.realpath == dest.realpath

      FileUtils.mkdir_p(dest)
      Dir[src.join("bootstrap-icons.woff*")].each do |file|
        target = dest.join(File.basename(file))
        next if target.exist? && File.identical?(file, target)

        FileUtils.cp(file, dest)
      end
    end
  end
end

namespace :assets do
  desc "Copy Bootstrap Icons fonts into public/fonts and /assets/fonts"
  task :copy_icon_fonts do
    IconFonts.copy_to(
      Rails.root.join("public/fonts"),
      Rails.root.join("app/assets/builds/fonts"),
      Rails.public_path.join("assets/fonts")
    )
  end
end

# Copy before precompile so Propshaft can digest relative ./fonts URLs in old CSS.
# Copy after as well: precompile clears public/assets, and compiled CSS may still
# request undigested /assets/fonts/bootstrap-icons.woff2.
if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance([ "assets:copy_icon_fonts" ])
  Rake::Task["assets:precompile"].enhance do
    IconFonts.copy_to(
      Rails.root.join("public/fonts"),
      Rails.public_path.join("assets/fonts")
    )
  end
end
