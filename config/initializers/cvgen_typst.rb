# frozen_string_literal: true

# Ensure Typst can see Google Fonts copied into the workspace, even when the
# installed cvgen gem is older than the FontResolver + --font-path support.
module CvgenTypstFontPath
  def compile_typst!(layout_path, pdf_path)
    fonts_dir = @root.join("fonts")
    cmd = [ "typst", "compile", "--root", @root.to_s ]
    cmd += [ "--font-path", fonts_dir.to_s ] if fonts_dir.directory?
    cmd += [ layout_path.to_s, pdf_path.to_s ]
    stdout, stderr, status = Open3.capture3(*cmd, chdir: @root.to_s)
    return if status.success?

    message = [ stderr, stdout ].reject(&:empty?).join("\n")
    raise Cvgen::SchemaError, "typst compile failed:\n#{message}"
  end
end

ENV["CVGEN_FONT_CACHE"] ||= Rails.root.join("tmp/google-fonts").to_s
Cvgen::Builder.prepend(CvgenTypstFontPath) unless Cvgen::Builder.ancestors.include?(CvgenTypstFontPath)
