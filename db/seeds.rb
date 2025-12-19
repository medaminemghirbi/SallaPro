# db/seeds.rb
require "faker"
require "open-uri"
require "yaml"
require "csv"
require "net/http"
require "json"


  puts "Seeding Company types..."
  starting_order = 0

  YAML.load_file(Rails.root.join("db", "data", "seeds", "company_types.yml")).each do |disease_data|
    starting_order += 1

    CompanyType.create!(
      name: disease_data["name"],
      description: disease_data["description"],
      key: disease_data["key"]
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


# === Seed Admin + it company ===
admin_avatar = download_image("https://thumbs.dreamstime.com/b/admin-reliure-de-bureau-sur-le-bureau-en-bois-sur-la-table-crayon-color%C3%A9-79046621.jpg")

if admin_avatar
  admin = Admin.create!(
    email: "admin@farhatn.com",
    firstname: "Admin",
    lastname: "Admin",
    password: "12345678",
    type: "Admin",
    password_confirmation: "12345678",
    confirmed_at: Time.zone.now
  )
  admin.avatar.attach(io: admin_avatar, filename: "admin_avatar.jpg", content_type: "image/jpeg")
  puts "✔️ Admin seeded"
end
user = Admin.first
Company.create!(
  user: user,
  name: "Salle Sghaier",
  company_type_id: CompanyType.find_by(key: "salle_des_fetes").id,
  active: true
)
