# frozen_string_literal: true

module Admin
  class CompaniesController < BaseController
    before_action :set_company, only: %i[edit update destroy]

    def index
      @q = params[:q].to_s.strip
      @companies = Company.search_text(@q).order(:official_name)
    end

    def new
      @company = Company.new(kind: :employer, country: "PL", legal_id_kind: :nip)
    end

    def create
      @company = Company.new(company_params)
      if @company.save
        redirect_to admin_companies_path, notice: t("admin.companies.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @company.update(company_params)
        redirect_to admin_companies_path, notice: t("admin.companies.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @company.destroy
        redirect_to admin_companies_path, notice: t("admin.companies.deleted")
      else
        redirect_to admin_companies_path, alert: t("admin.companies.cannot_delete")
      end
    end

    private

    def set_company
      @company = Company.find(params[:id])
    end

    def company_params
      params.require(:company).permit(
        :shortcut, :official_name, :kind, :country, :legal_id_kind, :legal_id,
        :street, :city, :postal_code
      )
    end
  end
end
