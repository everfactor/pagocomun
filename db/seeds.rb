# Clear existing data (optional - comment out if you want to keep existing data)
# Organization.destroy_all
# User.destroy_all
# Unit.destroy_all

puts "Creating base organization..."

# Create base organization
organization = Organization.find_or_create_by!(transbank_id: "TBK-ORG-001") do |org|
  org.name = "Pago Común Demo Organization"
  org.rut = "76.123.456-7"
  org.slug = "demo-org"
  org.active = true
  org.org_type = :community
  org.address = "Av. Providencia 1208, of 207, Santiago"
  org.tbk_child_commerce_code = "597055555532"
end

puts "✓ Organization created: #{organization.name}"

puts "\nCreating super admin user..."

# Create super admin user
admin_user = User.find_or_create_by!(email_address: "admin@pagocomun.com") do |user|
  user.first_name = "Admin"
  user.last_name = "User"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = :super_admin
  user.organization = organization
  user.status = :approved
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
  unit = Unit.find_or_create_by!(
    organization: organization,
    number: unit_data[:number],
    tower: unit_data[:tower]
  ) do |u|
    u.proration = unit_data[:proration]
  end
  puts "  ✓ Unit created: #{unit_data[:tower]}-#{unit_data[:number]}"
end

puts "\n✓ Seed data created successfully!"
puts "\nYou can now log in with:"
puts "  Email: admin@pagocomun.com"
puts "  Password: password123"
