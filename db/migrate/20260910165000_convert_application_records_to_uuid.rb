# frozen_string_literal: true

class ConvertApplicationRecordsToUuid < ActiveRecord::Migration[8.1]
  def up
    return if uuid_primary_key?(:users)

    drop_table :cv_profile_versions, if_exists: true
    drop_table :cv_profiles, if_exists: true
    drop_table :cv_documents, if_exists: true
    drop_table :themes, if_exists: true
    drop_table :users, if_exists: true, force: :cascade

    create_table :users, id: :uuid do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string :role, null: false, default: "jobseeker"
      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :role

    create_table :themes, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :kind, null: false, default: "system"
      t.references :user, type: :uuid, foreign_key: true
      t.string :file, null: false
      t.timestamps
    end

    add_index :themes, :kind
    add_index :themes, :slug, unique: true, where: "kind = 'system'"
    add_index :themes, %i[user_id slug], unique: true, where: "kind = 'personal'"

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
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def uuid_primary_key?(table)
    return false unless table_exists?(table)

    connection.columns(table).find { |column| column.name == "id" }&.type == :uuid
  end
end
