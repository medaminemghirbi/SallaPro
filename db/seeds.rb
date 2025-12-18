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


# === Seed Admin ===
puts "👤 Seeding Admin..."
admin_avatar = download_image("https://thumbs.dreamstime.com/b/admin-reliure-de-bureau-sur-le-bureau-en-bois-sur-la-table-crayon-color%C3%A9-79046621.jpg")

if admin_avatar
  admin = Admin.create!(
    email: "Admin@example.com",
    firstname: "Admin",
    lastname: "Admin",
    password: "123456",
    password_confirmation: "123456",
    confirmed_at: Time.zone.now
  )
  admin.avatar.attach(io: admin_avatar, filename: "admin_avatar.jpg", content_type: "image/jpeg")
  puts "✔️ Admin seeded"
else
  puts "⚠️ Failed to download admin avatar"
end
