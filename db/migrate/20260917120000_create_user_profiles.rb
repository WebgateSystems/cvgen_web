# frozen_string_literal: true

class CreateUserProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :user_profiles, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true, index: { unique: true }
      t.string :display_name
      t.string :location
      t.text :about
      t.string :avatar
      t.jsonb :analysis, null: false, default: {}
      t.datetime :analyzed_at
      t.timestamps
    end
  end
end
