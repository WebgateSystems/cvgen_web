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

SEED_COMPANIES = [
  { shortcut: "YND", official_name: "YND Sp. z o.o.", kind: :employer, legal_id: "5252344078" },
  { shortcut: "Strategic Staffing", official_name: "Strategic Staffing Sp. z o.o.", kind: :agency, legal_id: "5213678901" },
  { shortcut: "De Actief", official_name: "De Actief B.V.", kind: :agency, country: "NL", legal_id_kind: :vat, legal_id: "NL123456789B01" },
  { shortcut: "RejestrujZwierzaki", official_name: "RejestrujZwierzaki sp. z o.o.", kind: :employer, legal_id: "1132994455" },
  { shortcut: "Security", official_name: "Security Labs S.A.", kind: :employer, legal_id: "7010882211" },
  { shortcut: "Spreads", official_name: "Spreads Sp. z o.o.", kind: :employer, legal_id: "5272844001" },
  { shortcut: "Vendio", official_name: "Vendio Sp. z o.o.", kind: :employer, legal_id: "9542593302" },
  { shortcut: "Airmail", official_name: "Airmail Inc.", kind: :employer, country: "US", legal_id_kind: :ein, legal_id: "123456789" },
  { shortcut: "OGN Solutions", official_name: "OGN Solutions Sp. z o.o.", kind: :employer, legal_id: "6340127788" },
  { shortcut: "Sofomo", official_name: "Sofomo Sp. z o.o.", kind: :employer, legal_id: "6762471100" },
  { shortcut: "Religence", official_name: "Religence Sp. z o.o.", kind: :employer, legal_id: "8981002233" },
  { shortcut: "Initech", official_name: "Initech Sp. z o.o.", kind: :employer, legal_id: "1180004455" },
  { shortcut: "Acme Platform", official_name: "Acme Platform Ltd", kind: :employer, country: "GB", legal_id_kind: :company_number, legal_id: "12345678" },
  { shortcut: "Globex", official_name: "Globex Corporation", kind: :employer, country: "US", legal_id_kind: :ein, legal_id: "987654321" },
  { shortcut: "Umbrella", official_name: "Umbrella Corp Sp. z o.o.", kind: :employer, legal_id: "2223334445" }
].freeze

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

def seed_company!(attrs)
  country = attrs[:country] || "PL"
  legal_id_kind = attrs[:legal_id_kind] || :nip
  company = Company.find_or_initialize_by(
    country: country,
    legal_id_kind: legal_id_kind,
    legal_id: attrs[:legal_id]
  )
  company.assign_attributes(
    shortcut: attrs[:shortcut],
    official_name: attrs[:official_name],
    kind: attrs[:kind],
    street: attrs[:street] || "Prosta 18",
    city: attrs[:city] || "Warsaw",
    postal_code: attrs[:postal_code] || "00-850"
  )
  company.save!
  company
end

def seed_applications!(user, companies_by_shortcut, count: 45)
  statuses = JobApplication::STATUSES
  work_modes = JobApplication::WORK_MODES
  contracts = JobApplication::CONTRACT_TYPES
  now = Time.current

  count.times do |index|
    n = index + 1
    position, shortcut = SEED_APPLICATIONS[index % SEED_APPLICATIONS.size]
    company = companies_by_shortcut.fetch(shortcut)
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
      email: "jobs@#{shortcut.parameterize}.example",
      dropout_reason: (JobApplication::DROPOUT_STATUSES.include?(statuses[index % statuses.size]) ? "no_offer" : nil)
    )
    record.save!
    record.update_columns(updated_at: now - (count - n).hours, created_at: now - (count - n).days)
  end

  puts "Seeded #{count} applications for #{user.email}"
end

def seed_ratings!(user, companies)
  samples = companies.first(4)
  samples.each_with_index do |company, index|
    rating = user.company_ratings.find_or_initialize_by(company: company)
    rating.assign_attributes(
      responsiveness: 3 + (index % 3),
      seriousness: 2 + (index % 4),
      human_process: 4,
      fairness: 3 + (index % 2),
      comment: "Seed rating for #{company.display_name}."
    )
    rating.save!
  end
end

admin = seed_user!(email: "rordev@webgate.pro", password: "admin123!", role: :admin)
jobseeker = seed_user!(email: "user@example.com", password: "password123!", role: :jobseeker)
seed_user!(email: "hr@example.com", password: "password123!", role: :recruiter)

companies_by_shortcut = SEED_COMPANIES.to_h do |attrs|
  company = seed_company!(attrs)
  [ company.shortcut, company ]
end

Theme.import_system_from_gem!
seed_applications!(admin, companies_by_shortcut)
seed_applications!(jobseeker, companies_by_shortcut)
seed_ratings!(jobseeker, companies_by_shortcut.values)
puts "Seeded #{Company.count} companies"
