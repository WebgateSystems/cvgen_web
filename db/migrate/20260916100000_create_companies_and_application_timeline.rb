# frozen_string_literal: true

class CreateCompaniesAndApplicationTimeline < ActiveRecord::Migration[8.1]
  def up
    create_table :companies, id: :uuid do |t|
      t.string :shortcut
      t.string :official_name, null: false
      t.string :kind, null: false, default: "employer"
      t.string :country
      t.string :legal_id_kind
      t.string :legal_id
      t.string :street
      t.string :city
      t.string :postal_code
      t.timestamps
    end

    add_index :companies, :official_name
    add_index :companies, :shortcut
    add_index :companies, :kind
    add_index :companies, :country
    add_index :companies, %i[country legal_id_kind legal_id],
              unique: true,
              where: "legal_id IS NOT NULL AND legal_id_kind IS NOT NULL AND country IS NOT NULL",
              name: "index_companies_on_legal_identity"

    add_reference :job_applications, :company, type: :uuid, foreign_key: true, index: true

    backfill_companies

    change_column_null :job_applications, :company_id, false
    remove_column :job_applications, :company

    create_table :company_ratings, id: :uuid do |t|
      t.references :company, null: false, type: :uuid, foreign_key: true
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.integer :responsiveness, null: false, default: 0
      t.integer :seriousness, null: false, default: 0
      t.integer :human_process, null: false, default: 0
      t.integer :fairness, null: false, default: 0
      t.decimal :overall, precision: 2, scale: 1, null: false
      t.text :comment
      t.timestamps
    end

    add_index :company_ratings, %i[company_id user_id], unique: true

    create_table :application_events, id: :uuid do |t|
      t.references :job_application, null: false, type: :uuid, foreign_key: true
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :kind, null: false
      t.string :from_status
      t.string :to_status
      t.string :dropout_reason
      t.text :body
      t.timestamps
    end

    add_index :application_events, %i[job_application_id created_at]
  end

  def down
    drop_table :application_events
    drop_table :company_ratings

    add_column :job_applications, :company, :string
    execute(<<~SQL.squish)
      UPDATE job_applications AS ja
      SET company = COALESCE(NULLIF(c.shortcut, ''), c.official_name, 'Unknown')
      FROM companies c
      WHERE c.id = ja.company_id
    SQL
    change_column_null :job_applications, :company, false
    remove_reference :job_applications, :company, foreign_key: true

    drop_table :companies
  end

  private

  def backfill_companies
    say_with_time "Backfilling companies from job_applications.company" do
      grouped = {}
      select_all("SELECT id, company FROM job_applications").each do |row|
        name = row["company"].to_s.strip
        name = "Unknown" if name.blank?
        grouped[name] ||= []
        grouped[name] << row["id"]
      end

      grouped.each do |name, ids|
        company_id = insert_legacy_company(name)
        ids.each_slice(500) do |batch|
          quoted = batch.map { |id| connection.quote(id) }.join(", ")
          execute("UPDATE job_applications SET company_id = #{connection.quote(company_id)} WHERE id IN (#{quoted})")
        end
      end
    end
  end

  def insert_legacy_company(name)
    now = connection.quote(Time.current)
    quoted_name = connection.quote(name)
    result = execute(<<~SQL.squish)
      INSERT INTO companies (id, shortcut, official_name, kind, created_at, updated_at)
      VALUES (gen_random_uuid(), #{quoted_name}, #{quoted_name}, 'employer', #{now}, #{now})
      RETURNING id
    SQL
    result.first["id"]
  end
end
