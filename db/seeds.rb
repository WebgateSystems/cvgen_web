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

SEED_APPLICATIONS = [
  [ "Regular Ruby Developer", "YND" ],
  [ "Mid-Senior Ruby on Rails Developer", "Strategic Staffing" ],
  [ "Fullstack Ruby on Rails Developer", "De Actief" ],
  [ "Ruby On Rails Developer", "RejestrujZwierzaki" ],
  [ "Ruby on Rails developer", "Security" ],
  [ "Ruby on Rails Developer", "Spreads" ],
  [ "Ruby on Rails Developer", "Vendio" ],
  [ "Ruby on Rails Developer", "Airmail" ],
  [ "Ruby Developer", "OGN Solutions" ],
  [ "Ruby Developer", "Sofomo" ],
  [ "Programista Ruby on Rails", "Religence" ],
  [ "Ruby on Rails Developer", "Initech" ],
  [ "Senior Rails Engineer", "Acme Platform" ],
  [ "Backend Engineer (Ruby)", "Globex" ],
  [ "Rails Developer", "Umbrella" ]
].freeze

def seed_applications!(user, count: 45)
  statuses = JobApplication::STATUSES
  work_modes = JobApplication::WORK_MODES
  contracts = JobApplication::CONTRACT_TYPES
  now = Time.current

  count.times do |index|
    n = index + 1
    position, company = SEED_APPLICATIONS[index % SEED_APPLICATIONS.size]
    record = user.job_applications.find_or_initialize_by(link: "https://cvgen.example/seed/#{n}")
    record.assign_attributes(
      position: position,
      company: company,
      posted_on: Date.current - (count - n).days,
      status: statuses[index % statuses.size],
      expected_salary: "#{12_000 + (index * 250)} – #{16_000 + (index * 250)} PLN",
      offered_salary: (index.even? ? "#{15_000 + (index * 200)} PLN netto" : nil),
      work_mode: work_modes[index % work_modes.size],
      employment_type: "full_time",
      contract_type: contracts[index % contracts.size],
      email: "jobs@#{company.parameterize}.example"
    )
    record.save!
    record.update_columns(updated_at: now - (count - n).hours, created_at: now - (count - n).days)
  end

  puts "Seeded #{count} applications for #{user.email}"
end

admin = seed_user!(email: "rordev@webgate.pro", password: "admin123!", role: :admin)
jobseeker = seed_user!(email: "user@example.com", password: "password123!", role: :jobseeker)
seed_user!(email: "hr@example.com", password: "password123!", role: :recruiter)

Theme.import_system_from_gem!
seed_applications!(admin)
seed_applications!(jobseeker)
