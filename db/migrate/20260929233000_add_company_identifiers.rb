# frozen_string_literal: true

class AddCompanyIdentifiers < ActiveRecord::Migration[8.1]
  def up
    create_table :company_identifiers, id: :uuid do |t|
      t.references :company, null: false, type: :uuid, foreign_key: true
      t.string :kind, null: false
      t.string :value, null: false
      t.timestamps
    end
    add_index :company_identifiers, %i[kind value], unique: true

    execute <<~SQL.squish
      INSERT INTO company_identifiers (id, company_id, kind, value, created_at, updated_at)
      SELECT gen_random_uuid(), id,
        CASE
          WHEN legal_id_kind = 'vat' AND legal_id ~ '^[A-Za-z]{2}' THEN 'vat_eu'
          ELSE legal_id_kind
        END,
        CASE
          WHEN legal_id_kind = 'vat' AND legal_id ~ '^[A-Za-z]{2}'
            THEN upper(regexp_replace(legal_id, '[[:space:]-]+', '', 'g'))
          ELSE regexp_replace(legal_id, '[[:space:]-]+', '', 'g')
        END,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM companies
      WHERE legal_id IS NOT NULL AND btrim(legal_id) <> '' AND legal_id_kind IS NOT NULL
    SQL

    remove_index :companies, name: "index_companies_on_legal_identity"
    remove_column :companies, :legal_id
    remove_column :companies, :legal_id_kind
  end

  def down
    add_column :companies, :legal_id_kind, :string
    add_column :companies, :legal_id, :string
    add_index :companies, %i[country legal_id_kind legal_id],
              unique: true,
              where: "legal_id IS NOT NULL AND legal_id_kind IS NOT NULL AND country IS NOT NULL",
              name: "index_companies_on_legal_identity"

    execute <<~SQL.squish
      UPDATE companies AS c
      SET legal_id_kind = i.kind, legal_id = i.value
      FROM (
        SELECT DISTINCT ON (company_id) company_id, kind, value
        FROM company_identifiers
        ORDER BY company_id, created_at
      ) AS i
      WHERE c.id = i.company_id
    SQL

    drop_table :company_identifiers
  end
end
