# db/seeds.rb
require "faker"
require "open-uri"
require "yaml"
require "csv"
require "net/http"
require "json"


  puts "Seeding Company types..."
  starting_order = 0

  YAML.load_file(Rails.root.join("db", "data", "seeds", "categories.yml")).each do |disease_data|
    starting_order += 1

    Categorie.create!(
      name: disease_data["name"],
      description: disease_data["description"],
      key: disease_data["key"],
      resource_type: disease_data["resource_type"]
    )
  end
  puts "Seeding Company types done"
puts "Seeding Done ✅"

def download_image(url)
  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri)
  response.is_a?(Net::HTTPSuccess) ? StringIO.new(response.body) : nil
end


# === Seed Superadmin ===
puts "👤 Seeding Superadmin..."
admin_avatar = download_image("https://thumbs.dreamstime.com/b/admin-reliure-de-bureau-sur-le-bureau-en-bois-sur-la-table-crayon-color%C3%A9-79046621.jpg")

if admin_avatar
  superadmin = Superadmin.create!(
    email: "superadmin@farhatn.com",
    firstname: "Superadmin",
    lastname: "Superadmin",
    password: "12345678",
    type: "Superadmin",
    password_confirmation: "12345678",
    confirmed_at: Time.zone.now
  )
  superadmin.avatar.attach(io: admin_avatar, filename: "admin_avatar.jpg", content_type: "image/jpeg")
  puts "✔️ SuperAdmin seeded"
else
  puts "⚠️ Failed to download superadmin avatar"
end
# === Seed Admin + its Company + Trial Subscription ===
admin_avatar = download_image("https://thumbs.dreamstime.com/b/admin-reliure-de-bureau-sur-le-bureau-en-bois-sur-la-table-crayon-color%C3%A9-79046621.jpg")

if admin_avatar
  admin = Admin.create!(
    email: "admin@farhatn.com",
    firstname: "Admin",
    lastname: "Admin",
    password: "12345678",
    password_confirmation: "12345678",
    type: "Admin",
    confirmed_at: Time.zone.now
  )

  admin.avatar.attach(
    io: admin_avatar,
    filename: "admin_avatar.jpg",
    content_type: "image/jpeg"
  )

  puts "✔️ Admin seeded"
end

# Ensure admin exists
admin = Admin.find_by(email: "admin@farhatn.com")

# Create company
company = Company.create!(
  user_id: admin.id, # link admin to company
  name: "Salle Sghaier"
)

# Create trial subscription for the company
Subscription.create!(
  company_id: company.id,
  plan: 0, # trial
  status: 0, # active
  start_date: Date.today,
  end_date: Date.today + 14.days
)
puts "✔️ Company seeded"
