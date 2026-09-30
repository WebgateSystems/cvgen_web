# frozen_string_literal: true

class AddOfferSectionsAndApplicationLookups < ActiveRecord::Migration[8.1]
  def change
    add_column :job_applications, :sections, :jsonb, null: false, default: []

    create_table :application_lookups, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :company, foreign_key: true, type: :uuid
      t.string :source_url, null: false
      t.string :status, null: false, default: "queued"
      t.string :step
      t.text :error
      t.jsonb :payload, null: false, default: {}
      t.timestamps
    end
  end
end
