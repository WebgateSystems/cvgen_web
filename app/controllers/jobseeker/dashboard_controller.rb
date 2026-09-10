# frozen_string_literal: true

module Jobseeker
  class DashboardController < BaseController
    def show
      @personal_themes = current_user.themes.personal.order(:name)
      @system_themes_count = Theme.system.count
      @profiles = current_user.cv_profiles.includes(:versions).order(:name)
    end
  end
end
