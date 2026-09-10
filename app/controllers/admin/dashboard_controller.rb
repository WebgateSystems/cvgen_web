# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def show
      @users_count = User.count
      @admins_count = User.admin.count
      @jobseekers_count = User.jobseeker.count
      @recruiters_count = User.recruiter.count
      @themes_count = Theme.count
    end
  end
end
