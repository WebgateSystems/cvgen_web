# frozen_string_literal: true

class CvImportStore
  ROOT = Rails.root.join("tmp/cv_imports")

  def self.write(uploads)
    dir = ROOT.join(SecureRandom.uuid)
    FileUtils.mkdir_p(dir)
    Array(uploads).flatten.filter_map.with_index do |upload, index|
      next if upload.blank?

      filename = File.basename(upload.try(:original_filename).to_s)
      filename = "file-#{index}" if filename.blank?
      safe = filename.gsub(/[^\w.\-]+/, "_")
      path = dir.join("#{index}-#{safe}")
      upload.rewind if upload.respond_to?(:rewind)
      File.binwrite(path, upload.read)
      path.to_s
    end
  end

  def self.open(path)
    file = File.open(path, "rb")
    name = File.basename(path).sub(/\A\d+-/, "")
    file.define_singleton_method(:original_filename) { name }
    file
  end

  def self.cleanup(paths)
    return if paths.blank?

    dir = File.dirname(Array(paths).first)
    return unless dir.include?("/cv_imports/")

    FileUtils.rm_rf(dir)
  end
end
