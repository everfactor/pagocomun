# Clear existing data (optional - comment out if you want to keep existing data)
# Organization.destroy_all
# User.destroy_all
# Unit.destroy_all

puts "Creating base organization..."

# Create base organization
organization = Organization.find_or_create_by!(tbk_child_commerce_code: "597055555532") do |org|
  org.name = "Pago Común Demo Organization"
  org.rut = "76.123.456-7"
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

puts "\nCreating units..."

# Create units for the organization
units_data = [
  { number: "101", tower: "A", proration: 1.0 },
  { number: "102", tower: "A", proration: 1.0 },
  { number: "201", tower: "B", proration: 1.2 },
  { number: "202", tower: "B", proration: 1.2 }
]

units_data.each do |unit_data|
  unit = Unit.find_or_initialize_by(
    organization: organization,
    number: unit_data[:number],
    tower: unit_data[:tower]
  )
  if unit.new_record?
    unit.proration = unit_data[:proration]
    unit.email = "unit#{unit_data[:number]}@example.com"
    unit.save!
  end
  puts "  ✓ Unit created: #{unit_data[:tower]}-#{unit_data[:number]}"
end

puts "\n✓ Seed data created successfully!"
puts "\nYou can now log in with:"
puts "  Email: admin@pagocomun.com"
puts "  Password: password123"
