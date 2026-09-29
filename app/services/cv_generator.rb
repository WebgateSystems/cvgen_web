# frozen_string_literal: true

require "open3"
require "tmpdir"

class CvGenerator
  class Error < StandardError; end

  def initialize(build)
    @build = build
  end

  def self.typst_available?
    _out, _err, status = Open3.capture3("typst", "--version")
    status.success?
  rescue Errno::ENOENT
    false
  end

  def build_pdf
    raise Error, I18n.t("jobseeker.cvs.typst_missing") unless self.class.typst_available?

    Dir.mktmpdir("cvgen-") do |dir|
      root = Pathname(dir)
      prepare_workspace!(root)
      result = Cvgen::Builder.new(
        root: root,
        profile_name: @build.generator_profile,
        theme_name: @build.theme.slug,
        layout: @build.layout,
        content_name: @build.content_stem,
        fit: @build.fit,
        scale: @build.scale
      ).build!

      {
        pdf: File.binread(result[:pdf]),
        pages: result[:pages],
        scale: result[:scale],
        filename: @build.pdf_filename
      }
    end
  rescue Cvgen::SchemaError => e
    raise Error, e.message
  end

  private

  def prepare_workspace!(root)
    FileUtils.mkdir_p([ root.join("content"), root.join("themes"), root.join("profiles"), root.join("build") ])
    FileUtils.cp_r(Cvgen::ROOT.join("layouts").to_s, root.to_s)

    assets = Cvgen::ROOT.join("assets")
    FileUtils.cp_r(assets.to_s, root.to_s) if assets.exist?

    markdown = CvgenMarkdown.normalize(File.read(@build.version.file.path))
    root.join("content", "#{@build.content_stem}.md").write(markdown)
    payload = write_theme!(root)
    root.join("profiles", "#{@build.generator_profile}.yaml").write(@build.profile_payload.to_yaml)
    GoogleFontFiles.prepare!(root, payload)
    TypstFontName.patch_workspace!(root, payload) unless defined?(Cvgen::TtfFamilyName)
  end

  def write_theme!(root)
    yaml = File.read(@build.theme.file.path)
    yaml = ThemeYaml.patch(yaml, heading: @build.heading_font, body: @build.body_font)
    payload = YAML.safe_load(yaml, permitted_classes: []) || {}
    payload = Cvgen::Theme.deep_stringify(payload)
    yaml = ThemeYaml.patch(
      yaml,
      heading: TypstFontName.typst_family(payload.dig("fonts", "heading")),
      body: TypstFontName.typst_family(payload.dig("fonts", "body"))
    )
    root.join("themes", "#{@build.theme.slug}.yaml").write(yaml)
    payload
  end
end
