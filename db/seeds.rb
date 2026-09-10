# frozen_string_literal: true

def seed_user!(email:, password:, role:)
  user = User.find_or_initialize_by(email: email)
  user.password = password
  user.password_confirmation = password
  user.role = role
  user.save!
  puts "Seeded #{user.role} #{user.email} (id=#{user.id})"
  user
end

seed_user!(email: "rordev@webgate.pro", password: "admin123!", role: :admin)
seed_user!(email: "user@example.com", password: "password123!", role: :jobseeker)
seed_user!(email: "hr@example.com", password: "password123!", role: :recruiter)

Theme.import_system_from_gem!
