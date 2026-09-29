# frozen_string_literal: true

class CreateCompanyLookups < ActiveRecord::Migration[8.1]
  def change
    create_table :company_lookups, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.references :company, type: :uuid, foreign_key: true
      t.string :source_url, null: false
      t.string :status, null: false, default: "queued"
      t.string :step
      t.text :error
      t.jsonb :payload, null: false, default: {}
      t.timestamps
    end
  end
end
