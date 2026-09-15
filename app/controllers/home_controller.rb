# frozen_string_literal: true

class HomeController < ApplicationController
  def version
    return render(json: { version: AppIdService.version }, status: :ok) if request.format.json?

    render plain: AppIdService.version, status: :ok
  end

  def spinup_status
    render plain: "OK", status: :ok
  end
end
