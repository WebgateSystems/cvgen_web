# frozen_string_literal: true

class CreateCvProfilesAndVersions < ActiveRecord::Migration[8.1]
  def up
    create_table :cv_profiles, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end

    add_index :cv_profiles, %i[user_id slug], unique: true

    create_table :cv_profile_versions, id: :uuid do |t|
      t.references :cv_profile, null: false, type: :uuid, foreign_key: true
      t.integer :number, null: false
      t.string :tag
      t.string :file, null: false
      t.timestamps
    end

    add_index :cv_profile_versions, %i[cv_profile_id number], unique: true

    drop_table :cv_documents
  end

  def down
    create_table :cv_documents, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.string :file, null: false
      t.timestamps
    end

    add_index :cv_documents, %i[user_id slug], unique: true

    drop_table :cv_profile_versions
    drop_table :cv_profiles
  end
end
