# frozen_string_literal: true

class LocalesController < ApplicationController
  def update
    locale = params[:locale].to_s
    if AVAILABLE_LOCALES.include?(locale)
      response.set_cookie(
        "locale",
        value: locale,
        path: "/",
        expires: 20.years.from_now,
        same_site: :lax
      )
    end

    redirect_back fallback_location: root_path
  end
end
