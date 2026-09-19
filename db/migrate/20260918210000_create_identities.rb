# frozen_string_literal: true

class CreateIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :identities, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :email
      t.string :name
      t.timestamps
    end

    add_index :identities, %i[provider uid], unique: true
    add_index :identities, :email
  end
end
