# db/seeds.rb
require "faker"
require "open-uri"
require "yaml"
require "csv"
require "net/http"
require "json"

puts "🌱 Seeding data..."

def download_image(url)
  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri)
  response.is_a?(Net::HTTPSuccess) ? StringIO.new(response.body) : nil
end


# === Seed Superadmin ===
puts "👤 Seeding Superadmin..."
admin_avatar = download_image("https://thumbs.dreamstime.com/b/admin-reliure-de-bureau-sur-le-bureau-en-bois-sur-la-table-crayon-color%C3%A9-79046621.jpg")

if admin_avatar
  admin = Superadmin.create!(
    email: "superadmin@farhatn.com",
    firstname: "Superadmin",
    lastname: "Superadmin",
    password: "12345678",
    type: "Superadmin",
    password_confirmation: "12345678",
    confirmed_at: Time.zone.now
  )
  admin.avatar.attach(io: admin_avatar, filename: "admin_avatar.jpg", content_type: "image/jpeg")
  puts "✔️ Admin seeded"
else
  puts "⚠️ Failed to download superadmin avatar"
end
