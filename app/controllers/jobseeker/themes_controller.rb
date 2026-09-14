# frozen_string_literal: true

module Jobseeker
  class ThemesController < BaseController
    before_action :set_theme, only: %i[edit update destroy]

    def index
      @personal_themes = current_user.themes.personal.order(:name)
      @system_themes = Theme.system.order(:name)
    end

    def new
      @theme = current_user.themes.new(kind: :personal)
    end

    def create
      @theme = current_user.themes.new(theme_params.merge(kind: :personal, user: current_user))
      if @theme.save
        redirect_to jobseeker_themes_path, notice: t("jobseeker.themes.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @theme.update(theme_params)
        redirect_to jobseeker_themes_path, notice: t("jobseeker.themes.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @theme.destroy
      redirect_to jobseeker_themes_path, notice: t("jobseeker.themes.deleted")
    end

    private

    def set_theme
      @theme = current_user.themes.personal.find(params[:id])
    end

    def theme_params
      params.require(:theme).permit(:name, :file)
    end
  end
end
