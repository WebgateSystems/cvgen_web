# frozen_string_literal: true

module Admin
  class ThemesController < BaseController
    before_action :set_theme, only: %i[edit update destroy]

    def index
      @themes = Theme.includes(:user).order(:kind, :name)
    end

    def new
      @theme = Theme.new(kind: :system)
    end

    def create
      @theme = Theme.new(theme_params)
      if @theme.save
        redirect_to admin_themes_path, notice: t("admin.themes.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @theme.update(theme_params)
        redirect_to admin_themes_path, notice: t("admin.themes.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @theme.destroy
      redirect_to admin_themes_path, notice: t("admin.themes.deleted")
    end

    private

    def set_theme
      @theme = Theme.find(params[:id])
    end

    def theme_params
      params.require(:theme).permit(:name, :kind, :user_id, :file)
    end
  end
end
