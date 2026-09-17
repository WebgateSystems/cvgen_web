# frozen_string_literal: true

module Jobseeker
  module ProfileEditor
    extend ActiveSupport::Concern

    private

    def load_profile_editor(markdown: nil)
      @versions = @profile.versions.order(number: :desc)
      @version = selected_profile_version
      @markdown = markdown.nil? ? CvgenMarkdown.normalize(@version&.raw_markdown.to_s) : markdown.to_s
      @front, @body = CvgenMarkdown.split_document(@markdown)
    end

    def selected_profile_version
      return @profile.latest_version if params[:version_id].blank?

      @profile.versions.find(params[:version_id])
    end
  end
end
