# frozen_string_literal: true

class CreateJobApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :job_applications, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :position, null: false
      t.string :company, null: false
      t.date :posted_on
      t.string :status, null: false, default: "reviewed"
      t.string :expected_salary
      t.string :offered_salary
      t.string :work_mode
      t.string :employment_type
      t.string :contract_type
      t.string :link
      t.string :email
      t.timestamps
    end

    add_index :job_applications, %i[user_id posted_on]
    add_index :job_applications, %i[user_id status]
  end
end
