# frozen_string_literal: true

class AddUserUpdatedAtIndexToJobApplications < ActiveRecord::Migration[8.1]
  def change
    add_index :job_applications, %i[user_id updated_at]
  end
end
