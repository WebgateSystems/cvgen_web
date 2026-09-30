# frozen_string_literal: true

class ApplicationLookupJob < ApplicationJob
  queue_as :default

  def perform(application_lookup_id, locale = I18n.default_locale.to_s)
    I18n.with_locale(locale) do
      lookup = ApplicationLookup.find(application_lookup_id)
      ApplicationFromOffer.new(lookup).call
    end
  end
end
