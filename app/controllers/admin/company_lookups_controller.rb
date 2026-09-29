# frozen_string_literal: true

module Admin
  class CompanyLookupsController < BaseController
    def create
      @lookup = CompanyLookup.new(lookup_params.merge(user: current_user, status: "queued"))
      if @lookup.save
        CompanyLookupJob.perform_later(@lookup.id, I18n.locale.to_s)
        redirect_to admin_company_lookup_path(@lookup)
      else
        @company = Company.new(kind: :employer, country: "PL")
        @tab = "url"
        render "admin/companies/new", status: :unprocessable_content
      end
    end

    def show
      @lookup = CompanyLookup.find(params[:id])
      @company = Company.new(@lookup.company_attributes)
      @lookup.identifier_attributes.each { |attrs| @company.identifiers.build(attrs) } if @lookup.status == "incomplete"
    end

    private

    def lookup_params
      params.require(:company_lookup).permit(:source_url)
    end
  end
end
