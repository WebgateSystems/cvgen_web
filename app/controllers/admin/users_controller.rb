# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[edit update destroy]

    def index
      @users = User.order(created_at: :desc)
    end

    def new
      @user = User.new(role: :jobseeker)
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_users_path, notice: t("admin.users.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attrs = user_params
      attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?

      if last_admin_demotion?(attrs)
        redirect_to admin_users_path, alert: t("admin.users.cannot_delete_last_admin")
        return
      end

      if @user.update(attrs)
        redirect_to admin_users_path, notice: t("admin.users.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: t("admin.users.cannot_delete_self")
        return
      end

      if @user.admin? && User.admin.count <= 1
        redirect_to admin_users_path, alert: t("admin.users.cannot_delete_last_admin")
        return
      end

      @user.destroy
      redirect_to admin_users_path, notice: t("admin.users.deleted")
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def last_admin_demotion?(attrs)
      return false unless @user.admin?
      return false if attrs[:role].blank? || attrs[:role] == "admin"

      User.admin.count <= 1
    end

    def user_params
      params.require(:user).permit(:email, :role, :password, :password_confirmation)
    end
  end
end
