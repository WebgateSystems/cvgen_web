# frozen_string_literal: true

module Jobseeker
  class StatisticsController < BaseController
    def show
      @stats = ApplicationStatistics.call(current_user, params[:period])
    end
  end
end
