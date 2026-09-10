# frozen_string_literal: true

admin_email = "rordev@webgate.pro"
admin_password = "admin123!"

user = User.find_or_initialize_by(email: admin_email)
user.password = admin_password
user.password_confirmation = admin_password
user.save!

puts "Seeded Devise user #{user.email} (id=#{user.id})"
