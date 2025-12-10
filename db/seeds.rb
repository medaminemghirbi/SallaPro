# db/seeds.rb
require "faker"
require "open-uri"
require "yaml"
require "csv"
require "net/http"
require "json"

puts "🌱 Seeding data..."

# === Constants and Utility Methods ===

def random_sousse_coordinates
  [rand(35.810..35.850).round(6), rand(10.580..10.650).round(6)]
end

def download_image(url)
  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri)
  response.is_a?(Net::HTTPSuccess) ? StringIO.new(response.body) : nil
end

def generate_random_appointment_time
  year = Time.now.year
  start_date = Date.new(year, 7, 7)
  end_date = Date.new(year, 7, 20)
  time_slots = []

  (start_date..end_date).each do |date|
    time = Time.zone.parse("09:00").change(year: date.year, month: date.month, day: date.day)
    while time <= Time.zone.parse("16:00").change(year: date.year, month: date.month, day: date.day)
      time_slots << time
      time += 30.minutes
    end
  end

  time_slots.sample
end



# === Seed AppConfig ===
AppConfig.create!(key: "mobile", value: "")
puts "✔️ AppConfig seeded"

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

# === Seed Doctors ===
puts "🩺 Seeding Doctors from CSV..."
csv_path = Rails.root.join("app/services/dermatologue_doctors.csv")
starting_order = 1

CSV.foreach(csv_path, headers: true).first(4).each_with_index do |row, index|
  lat, long = random_sousse_coordinates
  doctor = Doctor.create!(
    firstname: row["name"].split.first,
    lastname: row["name"].split[1..].join(" "),
    location: "sousse",
    latitude: lat,
    longitude: long,
    email: Faker::Internet.unique.email,
    email: "#{row['name'].split.first.downcase}.#{row['name'].split[1].downcase}@dermapro.com",
    order: starting_order + index,
    password: "123456",
    password_confirmation: "123456",
    plateform: rand(0..1),
    gender: rand(0..1),
    confirmed_at: Time.zone.now
  )

  3.times do
    number = Faker::PhoneNumber.phone_number
    doctor.phone_numbers.find_or_create_by(number: number) do |phone|
      phone.phone_type = %w[personal home fax].sample
    end
  end

  if row["avatar_src"].present?
    avatar_file = download_image(row["avatar_src"])
    if avatar_file
      doctor.avatar.attach(io: avatar_file, filename: File.basename(row["avatar_src"]), content_type: "image/jpeg")
    else
      puts "⚠️ Failed to download avatar for Doctor #{doctor.firstname}"
    end
  end

  puts "✔️ Doctor #{doctor.firstname} #{doctor.lastname} seeded"
end


# === Seed Patients ===
puts "🧑‍🤝‍🧑 Seeding Patients..."

TUNISIAN_FIRST_NAMES = %w[Amine Mohamed Ahmed Youssef Sami Khalil Rami Wassim Firas Bilel Anis]
TUNISIAN_LAST_NAMES = %w[BenAli Gharbi Trabelsi Bouzid Jaziri BenRomdhane Hammami Ayari Tlili Khlifi]

def download_realistic_image(gender)
  gender_folder = gender == 0 ? "men" : "women"
  url = "https://randomuser.me/api/portraits/#{gender_folder}/#{rand(1..99)}.jpg"
  URI.open(url)
rescue => e
  puts "⚠️ Error downloading image: #{e}"
  nil
end

4.times do |i|
  phone_number = Faker::PhoneNumber.phone_number.gsub(/\D/, "").slice(0, 8)
  gender = rand(0..1)

  patient = Patient.create!(
    email: Faker::Internet.unique.email,
    firstname: TUNISIAN_FIRST_NAMES.sample,
    lastname: TUNISIAN_LAST_NAMES.sample,
    password: "123456",
    password_confirmation: "123456",
    order: starting_order + i,
    phone_number: phone_number,
    plateform: rand(0..1),
    gender: gender,
    location: %w[sousse monastir nabeul bizerte].sample,
    confirmed_at: Time.zone.now
  )

  avatar_file = download_realistic_image(gender)
  if avatar_file
    patient.avatar.attach(io: avatar_file, filename: "#{patient.firstname}_avatar.jpg", content_type: "image/jpeg")
  else
    puts "⚠️ Failed to download avatar for Patient #{patient.firstname}"
  end

  puts "✔️ Patient #{patient.firstname} #{patient.lastname} seeded"
end

# === Seed Diseases (Maladies) ===
puts "🦠 Seeding Diseases..."
diseases = YAML.load_file(Rails.root.join("db", "diseases.yml"))
diseases.each_with_index do |data, i|
  maladie = Maladie.create!(
    maladie_name: data["maladie_name"],
    maladie_description: data["maladie_description"],
    synonyms: data["synonyms"],
    symptoms: data["symptoms"],
    causes: data["causes"],
    treatments: data["treatments"],
    prevention: data["prevention"],
    diagnosis: data["diagnosis"],
    references: data["references"],
    is_cancer: data["is_cancer"],
    order: i + 1
  )

  img_path = Rails.root.join("app/assets/images", data["image_path"])
  if File.exist?(img_path)
    maladie.image.attach(io: File.open(img_path), filename: data["image_path"], content_type: "image/png")
  else
    puts "⚠️ Image not found for #{maladie.maladie_name}"
  end
end

# # === Seed Consultations ===
# puts "📅 Seeding Consultations..."
# if Doctor.any? && Patient.any?
#   %i[pending approved rejected].each do |status|
#     10.times do
#       doctor = Doctor.all.sample
#       patient = Patient.all.sample
#       appointment_time = generate_random_appointment_time
#       appointment_date = appointment_time.to_date

#       # Vérifier unicité par doctor/patient/date
#       while Consultation.exists?(doctor: doctor, appointment: appointment_time) ||
#             Consultation.exists?(doctor: doctor, patient: patient, appointment: appointment_date.all_day)
#         appointment_time = generate_random_appointment_time
#         appointment_date = appointment_time.to_date
#         patient = Patient.all.sample
#       end

#       refus_reason = status == :rejected ? Faker::Lorem.sentence : nil

#       Consultation.create!(
#         appointment: appointment_time,
#         status: Consultation.statuses[status],
#         doctor: doctor,
#         patient: patient,
#         is_archived: false,
#         refus_reason: refus_reason
#       )
#       puts "✔️ Consultation #{status} on #{appointment_time.strftime("%d/%m/%Y %H:%M")}"
#     end
#   end
#   puts "✅ Consultations seeded"
# else
#   puts "⚠️ Doctors or Patients missing — skipping consultations"
# end


# === Seed Blogs ===
puts "📝 Seeding Blogs..."

maladies = Maladie.all
doctors = Doctor.all

10.times do |i|
  maladie = maladies.sample
  doctor = doctors.sample

  content = "#{maladie.maladie_name} is a medical condition that affects many people. " \
            "It is typically characterized by symptoms such as #{maladie.symptoms || 'varied symptoms'}. " \
            "Common causes include #{maladie.causes || 'genetic or environmental factors'}. " \
            "Diagnosis is usually made through #{maladie.diagnosis || 'a clinical assessment'}. " \
            "Treatment options may involve #{maladie.treatments || 'medication and therapy'}. " \
            "Preventive measures can include #{maladie.prevention || 'healthy lifestyle habits'}."

  blog = Blog.create!(
    title: maladie.maladie_name,
    content: content,
    order: i + 1,
    doctor: doctor,
    maladie: maladie
  )

  puts "✔️ Blog '#{blog.title}' seeded"
end


  puts "💬 Seeding Messages..."

  PATIENT_MESSAGES = [
    "J’ai des plaques rouges qui apparaissent sur mes bras.",
    "Ma peau me gratte surtout la nuit, que faire ?",
    "J’ai remarqué un grain de beauté qui a changé de forme.",
    "La crème prescrite brûle ma peau, est-ce normal ?",
    "Des boutons sont apparus après avoir utilisé un nouveau savon.",
    "Mon cuir chevelu est très irrité ces derniers temps.",
    "Est-ce que cette éruption cutanée est contagieuse ?",
    "J’ai une allergie apparente, dois-je consulter en urgence ?",
    "Les démangeaisons s’aggravent malgré le traitement.",
    "Une tache foncée s’est formée sur ma joue récemment."
  ]

  DOCTOR_MESSAGES = [
    "Le patient présente une dermatite atopique modérée.",
    "Une biopsie cutanée est recommandée pour ce cas.",
    "Il s'agit d'un eczéma de contact probable, traitement topique conseillé.",
    "Surveillance d’un nævus suspect conseillé tous les 6 mois.",
    "Prescription d’une pommade corticoïde à appliquer deux fois par jour.",
    "Le patient souffre de psoriasis au niveau des coudes.",
    "Aucune lésion suspecte détectée, simple irritation cutanée.",
    "Le test allergologique est recommandé pour identifier les déclencheurs.",
    "Un traitement antifongique est prescrit pour la mycose observée.",
    "La peau présente des signes d’hyperpigmentation post-inflammatoire."
  ]

  puts "✔️ Creating a coherent chat-like conversation..."

  users = {
    doctors: User.where(type: 'Doctor').to_a,
    patients: User.where(type: 'Patient').to_a
  }

  conversation_length = 10
  conversation = []

  conversation_length.times do |i|
    if i.even? # Patient message
      sender = users[:patients].sample
      message_body = PATIENT_MESSAGES.sample
    else # Doctor reply
      sender = users[:doctors].sample
      message_body = DOCTOR_MESSAGES.sample
    end

    conversation << {
      body: message_body,
      sender_id: sender.id,
      created_at: Time.zone.now,
      updated_at: Time.zone.now,
      sender_type: sender.type,
      sender_name: sender.firstname
    }
  end

  conversation.each do |msg|
    Message.create!(
      body: msg[:body],
      sender_id: msg[:sender_id],
      created_at: msg[:created_at],
      updated_at: msg[:updated_at]
    )
    puts "💬 #{msg[:sender_type]} #{msg[:sender_name]} sent: “#{msg[:body]}”"
  end

  puts "✔️ #{conversation_length} coherent chat-like messages seeded"

puts "Seeding completed! Created #{Holiday.count} holidays."

puts "Seeding holidays 2025..."
# Set up the API endpoint URL
url = URI("https://api.api-ninjas.com/v1/holidays?country=TN&type=PUBLIC_HOLIDAY")

# Set up the HTTP request
request = Net::HTTP::Get.new(url)
request["x-API-KEY"] = "mYCPF5Bd6yRjMmCMSGkQnw==6aK6gP1eU5EjzpJw"  # Replace 'YOUR_API_KEY_HERE' with your actual API key

# Make the HTTP request and parse the response
response = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
  http.request(request)
end

# Parse the JSON response
holidays_data = JSON.parse(response.body)
# Seed the holidays table
holidays_data.each do |holiday|
  Holiday.create!(
    holiday_name: holiday["name"],
    holiday_date: holiday["date"],
    is_archived: false
  )
end
puts "Seeding completed! Created #{Holiday.count} holidays."

  puts "Seeding services..."
  starting_order = 0

  YAML.load_file(Rails.root.join("db", "services.yml")).each do |disease_data|
    starting_order += 1

    Service.create!(
      name: disease_data["name"],
      description: disease_data["description"],
      price: disease_data["price"],
      order: starting_order
    )
  end
  puts "Seeding services done"
puts "Seeding Done ✅"

# puts "Seeding done."



##TO USE IN PFE
# ## Find doctor and patient by email (single records)
# doctor = Doctor.find_by(email: "doctor@gmail.com")
# patient = Patient.third

# # Define the appointment datetime: May 26, 2025 at 10:00 AM (adjust year if needed)
# appointment_time = Time.zone.parse("2025-05-26 11:30")

# # Create the consultation
# consultation = Consultation.create!(
#   appointment: appointment_time,
#   status: "approved",   # or :approved if it's a symbol enum
#   doctor: doctor,
#   patient: patient
# )

# Consultation.approved.find_each do |consultation|
#   # Skip if a rating already exists for this consultation
#   next if Rating.exists?(consultation_id: consultation.id)

#   Rating.create!(
#     consultation_id: consultation.id,
#     rating_value: rand(1..5), # Random value from 1 to 5
#     comment: ["Excellent", "Good", "Average", "Needs improvement", "Poor"].sample
#   )
# end
