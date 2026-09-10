# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  self.implicit_order_column = "created_at"

  after_initialize :ensure_uuid

  private

  def ensure_uuid
    return unless new_record?
    return if id.present?

    self.id = SecureRandom.uuid
  end
end
