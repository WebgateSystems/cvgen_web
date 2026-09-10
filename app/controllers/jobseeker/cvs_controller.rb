# frozen_string_literal: true

module Jobseeker
  class CvsController < BaseController
    def show
      load_catalog
      @build = CvBuild.new(default_build_attrs)
      @build.user = current_user
    end

    def preview
      @build = CvBuild.new(build_params)
      @build.user = current_user
      unless @build.valid?
        return render plain: @build.errors.full_messages.to_sentence, status: :unprocessable_entity
      end

      result = CvGenerator.new(@build).build_pdf
      disposition = params[:download].present? ? "attachment" : "inline"
      send_data result[:pdf],
                type: "application/pdf",
                disposition: disposition,
                filename: result[:filename]
    rescue CvGenerator::Error => e
      render plain: e.message, status: :unprocessable_entity
    end

    private

    def load_catalog
      @profiles = current_user.cv_profiles.includes(:versions).order(:name)
      @themes = Theme.for_user(current_user).order(:kind, :name)
      @layouts = Cvgen::Catalog.layouts(Cvgen::ROOT)
      @generator_profiles = Cvgen::Catalog.profiles(Cvgen::ROOT).sort
      @generator_profile_options = @generator_profiles.map { |name| generator_profile_meta(name) }
      @versions_by_profile = @profiles.to_h do |profile|
        [
          profile.id.to_s,
          profile.versions.sort_by(&:number).reverse.map { |version|
            { id: version.id.to_s, label: version.label }
          }
        ]
      end
    end

    def default_build_attrs
      profile = current_user.cv_profiles.includes(:versions).order(:name).first
      version = profile&.latest_version
      default_profile = generator_profile_meta("default")
      theme = Theme.for_user(current_user).find_by(slug: default_profile[:theme]) ||
              Theme.for_user(current_user).order(:kind, :name).first

      {
        cv_profile_id: profile&.id&.to_s,
        cv_profile_version_id: version&.id&.to_s,
        theme_id: theme&.id&.to_s,
        layout: default_profile[:layout],
        generator_profile: "default",
        scale: 1.0,
        fit: false,
        max_pages: default_profile[:max_pages],
        max_experience_items: default_profile[:max_experience_items],
        include_skills: default_profile[:include_skills],
        exclude: default_profile[:exclude]
      }
    end

    def generator_profile_meta(name)
      return fallback_profile_meta(name) unless Cvgen::Catalog.profiles(Cvgen::ROOT).include?(name)

      profile = Cvgen::Profile.load(Cvgen::ROOT, name)
      {
        name: name,
        layout: profile.layout,
        theme: profile.theme_name,
        max_pages: (profile.data["max_pages"] || 2).to_i,
        max_experience_items: profile.data["max_experience_items"],
        include_skills: Array(profile.data.dig("include", "skills")).join(", "),
        exclude: Array(profile.data["exclude"]).join(", ")
      }
    end

    def fallback_profile_meta(name)
      {
        name: name,
        layout: "modern-stack",
        theme: "modern-blue",
        max_pages: 2,
        max_experience_items: nil,
        include_skills: "",
        exclude: ""
      }
    end

    def build_params
      params.fetch(:cv_build, {}).permit(
        :cv_profile_id, :cv_profile_version_id, :theme_id,
        :layout, :generator_profile, :scale, :fit, :max_pages,
        :max_experience_items, :include_skills, :exclude
      )
    end
  end
end
