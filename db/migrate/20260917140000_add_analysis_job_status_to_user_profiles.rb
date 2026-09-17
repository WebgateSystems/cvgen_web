# frozen_string_literal: true

class AddAnalysisJobStatusToUserProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :user_profiles, :analysis_status, :string, null: false, default: "idle"
    add_column :user_profiles, :analysis_step, :string
    add_column :user_profiles, :analysis_error, :text
    add_reference :user_profiles, :starter_cv_profile, type: :uuid, foreign_key: { to_table: :cv_profiles }
  end
end
