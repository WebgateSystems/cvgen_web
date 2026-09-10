# frozen_string_literal: true

class CreateCvDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :cv_documents, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.string :file, null: false
      t.timestamps
    end

    add_index :cv_documents, %i[user_id slug], unique: true
  end
end
