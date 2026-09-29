# frozen_string_literal: true

class CompanyLookupJob < ApplicationJob
  queue_as :default

  def perform(company_lookup_id, locale = I18n.default_locale.to_s)
    I18n.with_locale(locale) do
      lookup = CompanyLookup.find(company_lookup_id)
      CompanyFromOffer.new(lookup).call
    end
  end
end
