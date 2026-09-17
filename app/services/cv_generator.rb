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
    FileUtils.cp(@build.theme.file.path, root.join("themes", "#{@build.theme.slug}.yaml"))
    root.join("profiles", "#{@build.generator_profile}.yaml").write(@build.profile_payload.to_yaml)
  end
end
