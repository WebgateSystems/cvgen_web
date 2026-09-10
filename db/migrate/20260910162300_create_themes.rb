# frozen_string_literal: true

class CreateThemes < ActiveRecord::Migration[8.1]
  def change
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
  end
end
