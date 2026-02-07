# Clear existing data (optional - comment out if you want to keep existing data)
# Organization.destroy_all
# User.destroy_all
# Unit.destroy_all

puts "Creating base organization..."

# Create base organization
organization = Organization.find_or_create_by!(tbk_child_commerce_code: "597055555532") do |org|
  org.name = "Pago Común Demo Organization"
  org.rut = "76123456-0"
  org.slug = "demo-org"
  org.active = true
  org.org_type = :community
  org.address = "Av. Providencia 1208, of 207, Santiago"
end

puts "✓ Organization created: #{organization.name}"

puts "\nCreating super admin user..."

# Create super admin user
admin_user = User.find_or_initialize_by(email_address: "admin@pagocomun.com")
if admin_user.new_record?
  admin_user.assign_attributes(
    first_name: "Admin",
    last_name: "User",
    password: "password123",
    password_confirmation: "password123",
    role: :super_admin,
    organization: organization,
    status: :approved
  )
  admin_user.save!
end

puts "✓ Super admin created: #{admin_user.email_address}"

puts "\nCreating units and bills..."

# Create units for the organization
units_data = [
  {number: "101", tower: "A", proration: 1.0, pay_day: 5},
  {number: "102", tower: "A", proration: 1.0, pay_day: 5},
  {number: "201", tower: "B", proration: 1.2, pay_day: 10},
  {number: "202", tower: "B", proration: 1.2, pay_day: 10}
]

current_period = Time.current.strftime("%Y-%m")

units_data.each do |unit_data|
  unit = Unit.find_or_initialize_by(
    organization: organization,
    number: unit_data[:number],
    tower: unit_data[:tower]
  )
  if unit.new_record?
    unit.proration = unit_data[:proration]
    unit.pay_day = unit_data[:pay_day]
    unit.email = "unit#{unit_data[:number]}@example.com"
    unit.save!
  end
  puts "  ✓ Unit created: #{unit_data[:tower]}-#{unit_data[:number]}"

  # Create a bill for each unit
  bill = unit.bills.find_or_create_by!(period: current_period) do |b|
    b.amount = 50000 * unit.proration
    b.status = :pending
    b.due_date = Date.new(Time.current.year, Time.current.month, unit.pay_day)
  end
  puts "    ✓ Bill created for #{current_period}: $#{bill.amount}"
end

organization.update(last_bill_upload_period: current_period)

puts "\nCreating org_admin user..."

# Create org_admin user
org_admin = User.find_or_initialize_by(email_address: "orgadmin@pagocomun.com")
if org_admin.new_record?
  org_admin.assign_attributes(
    first_name: "Org",
    last_name: "Admin",
    password: "password123",
    password_confirmation: "password123",
    role: :org_admin,
    status: :approved
  )
  org_admin.save!
end

puts "✓ Org admin created: #{org_admin.email_address}"

puts "\nCreating 3 organizations..."

# Create 3 organizations
organizations = []
org_data = [
  {name: "Organization Alpha", rut: "76111111-6", slug: "org-alpha", tbk_child_commerce_code: "597055555533"},
  {name: "Organization Beta", rut: "76222222-1", slug: "org-beta", tbk_child_commerce_code: "597055555534"},
  {name: "Organization Gamma", rut: "76333333-7", slug: "org-gamma", tbk_child_commerce_code: "597055555535"}
]

org_data.each do |data|
  org = Organization.find_or_create_by!(tbk_child_commerce_code: data[:tbk_child_commerce_code]) do |o|
    o.name = data[:name]
    o.rut = data[:rut]
    o.slug = data[:slug]
    o.active = true
    o.org_type = :community
    o.address = "Sample Address"
  end
  organizations << org
  puts "  ✓ Organization created: #{org.name}"
end

puts "\nCreating 2 org_manager users..."

# Create 2 org_manager users
manager1 = User.find_or_initialize_by(email_address: "manager1@pagocomun.com")
if manager1.new_record?
  manager1.assign_attributes(
    first_name: "Manager",
    last_name: "One",
    password: "password123",
    password_confirmation: "password123",
    role: :org_manager,
    status: :approved
  )
  manager1.save!
end

manager2 = User.find_or_initialize_by(email_address: "manager2@pagocomun.com")
if manager2.new_record?
  manager2.assign_attributes(
    first_name: "Manager",
    last_name: "Two",
    password: "password123",
    password_confirmation: "password123",
    role: :org_manager,
    status: :approved
  )
  manager2.save!
end

puts "  ✓ Manager 1 created: #{manager1.email_address}"
puts "  ✓ Manager 2 created: #{manager2.email_address}"

puts "\nCreating organization memberships..."

# Associate org_admin with all 3 organizations
organizations.each do |org|
  OrganizationMembership.find_or_create_by!(
    organization: org,
    user: org_admin
  ) do |m|
    m.role = :org_admin
    m.active = true
  end
  puts "  ✓ Org admin associated with: #{org.name}"
end

# Associate first manager with first 2 organizations
[organizations[0], organizations[1]].each do |org|
  OrganizationMembership.find_or_create_by!(
    organization: org,
    user: manager1
  ) do |m|
    m.role = :org_manager
    m.active = true
  end
  puts "  ✓ Manager 1 associated with: #{org.name}"
end

# Associate second manager with last organization
OrganizationMembership.find_or_create_by!(
  organization: organizations[2],
  user: manager2
) do |m|
  m.role = :org_manager
  m.active = true
end
puts "  ✓ Manager 2 associated with: #{organizations[2].name}"

puts "\n✓ Seed data created successfully!"
puts "\nYou can now log in with:"
puts "  Email: admin@pagocomun.com"
puts "  Password: password123"
puts "\nOr with:"
puts "  Email: orgadmin@pagocomun.com (Org Admin)"
puts "  Email: manager1@pagocomun.com (Org Manager - 2 orgs)"
puts "  Email: manager2@pagocomun.com (Org Manager - 1 org)"
puts "  Password: password123 (for all)"
