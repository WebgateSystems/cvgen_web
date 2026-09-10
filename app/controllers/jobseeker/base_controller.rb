# frozen_string_literal: true

module Jobseeker
  class BaseController < ApplicationController
    layout "jobseeker"

    before_action :authenticate_jobseeker_studio!
  end
end
