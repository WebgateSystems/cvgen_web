# frozen_string_literal: true

class AddDraftStatusToCvProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :cv_profiles, :draft_status, :string, null: false, default: "idle"
    add_column :cv_profiles, :draft_error, :text
  end
end
