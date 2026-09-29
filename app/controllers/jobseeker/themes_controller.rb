# frozen_string_literal: true

module Jobseeker
  class ThemesController < BaseController
    before_action :set_personal_theme, only: %i[edit update destroy]
    before_action :set_clonable_theme, only: :clone

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
      if @theme.update(update_params)
        redirect_to jobseeker_themes_path, notice: t("jobseeker.themes.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def clone
      theme = ThemeCloner.call(source: @source_theme, user: current_user)
      redirect_to edit_jobseeker_theme_path(theme), notice: t("jobseeker.themes.cloned")
    end

    def destroy
      @theme.destroy
      redirect_to jobseeker_themes_path, notice: t("jobseeker.themes.deleted")
    end

    private

    def set_personal_theme
      @theme = current_user.themes.personal.find(params[:id])
    end

    def set_clonable_theme
      @source_theme = Theme.for_user(current_user).find(params[:id])
    end

    def theme_params
      params.require(:theme).permit(:name, :file, :yaml_text)
    end

    def update_params
      attrs = theme_params
      attrs.delete(:yaml_text) if attrs[:file].present?
      attrs
    end
  end
end
