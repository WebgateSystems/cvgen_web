# frozen_string_literal: true

module Jobseeker
  class VersionsController < BaseController
    include ProfileEditor

    before_action :set_profile

    def new
      @version = @profile.versions.new
    end

    def create
      record = @profile.versions.new(version_params)
      if record.save
        location = markdown_submit? ? jobseeker_profile_path(@profile, version_id: record.id) : jobseeker_profile_path(@profile)
        redirect_to location, notice: markdown_submit? ? t("jobseeker.versions.saved") : t("jobseeker.versions.created")
      elsif markdown_submit?
        @editor_errors = record.errors
        load_profile_editor(markdown: params.dig(:cv_profile_version, :markdown))
        render "jobseeker/profiles/show", status: :unprocessable_content
      else
        @version = record
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      @version = @profile.versions.find(params[:id])
      if @profile.versions.count <= 1
        redirect_to jobseeker_profile_path(@profile), alert: t("jobseeker.versions.cannot_delete_last")
      else
        @version.destroy
        redirect_to jobseeker_profile_path(@profile), notice: t("jobseeker.versions.deleted")
      end
    end

    private

    def set_profile
      @profile = current_user.cv_profiles.find(params[:profile_id])
    end

    def markdown_submit?
      params.dig(:cv_profile_version, :markdown).to_s.strip.present?
    end

    def version_params
      permitted = params.require(:cv_profile_version).permit(:file, :tag, :markdown)
      markdown = permitted.delete(:markdown).to_s
      if permitted[:file].blank? && markdown.strip.present?
        permitted[:file] = uploaded_markdown(markdown)
      end
      permitted
    end

    def uploaded_markdown(text)
      file = Tempfile.new([ "cv", ".md" ])
      file.write(CvgenMarkdown.normalize(text))
      file.flush
      file.rewind
      @markdown_tempfile = file
      ActionDispatch::Http::UploadedFile.new(
        filename: "cv.md",
        type: "text/markdown",
        tempfile: file
      )
    end
  end
end
