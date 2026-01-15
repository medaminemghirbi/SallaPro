# db/seeds.rb
# Application de réservation de Salles des Fêtes - SallaPro
# Seeds pour l'environnement de développement

require "faker"
require "open-uri"
require "yaml"
require "csv"
require "net/http"
require "json"

# Configuration Faker pour le français/Tunisie
Faker::Config.locale = 'fr'

def download_image(url)
  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri)
  response.is_a?(Net::HTTPSuccess) ? StringIO.new(response.body) : nil
rescue StandardError => e
  puts "⚠️ Erreur téléchargement image: #{e.message}"
  nil
end

# === Seed Categories ===
puts "🏷️ Seeding Categories (Types d'espaces et services)..."

YAML.load_file(Rails.root.join("db", "data", "seeds", "categories.yml")).each do |category_data|
  Categorie.find_or_create_by!(key: category_data["key"]) do |cat|
    cat.name = category_data["name"]
    cat.description = category_data["description"]
    cat.resource_type = category_data["resource_type"]
  end
end

puts "✔️ #{Categorie.count} catégories créées"

# === Seed Superadmin ===
puts "👤 Seeding Superadmin..."

superadmin = Superadmin.find_or_create_by!(email: "superadmin@sallapro.tn") do |user|
  user.firstname = "Mohamed"
  user.lastname = "Ben Ali"
  user.password = "12345678"
  user.password_confirmation = "12345678"
  user.type = "Superadmin"
  user.confirmed_at = Time.zone.now
  user.phone_number = "+21698000001"
  user.address = "Avenue Habib Bourguiba, Tunis"
  user.country = "Tunisie"
end

puts "✔️ Superadmin créé: #{superadmin.email}"

# === Seed Admin Principal + Sa Salle des Fêtes ===
puts "👤 Seeding Admin Principal..."

admin = Admin.find_or_create_by!(email: "admin@sallapro.tn") do |user|
  user.firstname = "Amine"
  user.lastname = "Sghaier"
  user.password = "12345678"
  user.password_confirmation = "12345678"
  user.type = "Admin"
  user.default_admin = true
  user.confirmed_at = Time.zone.now
  user.phone_number = "+21698123456"
  user.address = "Route de Sousse Km 5, Sfax"
  user.country = "Tunisie"
end

puts "✔️ Admin créé: #{admin.email}"

# Récupérer la catégorie "Salle des fêtes"
salle_category = Categorie.find_by(key: "salle_des_fetes")

# === Créer la Salle des Fêtes Principale ===
puts "🏛️ Seeding Salle des Fêtes Principale..."

company = Company.find_or_create_by!(user_id: admin.id) do |c|
  c.name = "Salle Sghaier"
  c.description = "Salle des fêtes de luxe pour mariages, fiançailles et événements. Capacité jusqu'à 500 personnes avec jardin, parking et traiteur sur place."
  c.phone_number = "+21674123456"
  c.billing_address = "Route de Sousse Km 5, 3000 Sfax, Tunisie"
  c.active = true
  c.categorie_id = salle_category&.id
end

puts "✔️ Salle des fêtes créée: #{company.name}"

# === Seed Départements de la Salle ===
puts "🏢 Seeding Départements..."

departments_data = [
  { name: "Administration", code: "ADM", description: "Gestion administrative et réservations", color: "#3B82F6" },
  { name: "Restauration", code: "REST", description: "Cuisine et service traiteur", color: "#EF4444" },
  { name: "Décoration", code: "DECO", description: "Décoration et mise en place des salles", color: "#10B981" },
  { name: "Technique", code: "TECH", description: "Son, lumière et équipements techniques", color: "#F59E0B" },
  { name: "Entretien", code: "ENT", description: "Nettoyage et maintenance", color: "#8B5CF6" }
]

departments_data.each do |dept_data|
  Department.find_or_create_by!(company_id: company.id, name: dept_data[:name]) do |dept|
    dept.code = dept_data[:code]
    dept.description = dept_data[:description]
    dept.color = dept_data[:color]
    dept.active = true
  end
end

puts "✔️ #{Department.count} départements créés"

# === Seed Employés ===
puts "👥 Seeding Employés..."

admin_dept = Department.find_by(code: "ADM", company_id: company.id)
resto_dept = Department.find_by(code: "REST", company_id: company.id)
deco_dept = Department.find_by(code: "DECO", company_id: company.id)
tech_dept = Department.find_by(code: "TECH", company_id: company.id)

employees_data = [
  { firstname: "Fatma", lastname: "Ben Salem", email: "fatma@sallapro.tn", position: "Responsable Réservations", department: admin_dept },
  { firstname: "Khaled", lastname: "Trabelsi", email: "khaled@sallapro.tn", position: "Chef Cuisinier", department: resto_dept },
  { firstname: "Sonia", lastname: "Gharbi", email: "sonia@sallapro.tn", position: "Décoratrice", department: deco_dept },
  { firstname: "Nabil", lastname: "Jaziri", email: "nabil@sallapro.tn", position: "Technicien Son & Lumière", department: tech_dept },
  { firstname: "Mariem", lastname: "Mansouri", email: "mariem@sallapro.tn", position: "Assistante Administrative", department: admin_dept }
]

employees_data.each do |emp_data|
  Employee.find_or_create_by!(email: emp_data[:email]) do |emp|
    emp.firstname = emp_data[:firstname]
    emp.lastname = emp_data[:lastname]
    emp.password = "12345678"
    emp.password_confirmation = "12345678"
    emp.type = "Employee"
    emp.confirmed_at = Time.zone.now
    emp.phone_number = "+2169#{rand(1000000..9999999)}"
    emp.company_id = company.id
    emp.department_id = emp_data[:department]&.id
    emp.position = emp_data[:position]
    emp.status = "active"
    emp.hire_date = Faker::Date.between(from: 2.years.ago, to: 6.months.ago)
    emp.country = "Tunisie"
  end
end

puts "✔️ #{Employee.count} employés créés"

# === Seed Matériels & Équipements ===
puts "🪑 Seeding Matériels & Équipements..."

materials_data = [
  # Mobilier
  { name: "Tables rondes 10 places", category: "Mobilier", quantity: 50, status: "active", location: "Entrepôt A" },
  { name: "Chaises dorées", category: "Mobilier", quantity: 500, status: "active", location: "Entrepôt A" },
  { name: "Tables cocktail", category: "Mobilier", quantity: 20, status: "active", location: "Entrepôt A" },
  { name: "Nappes blanches", category: "Linge", quantity: 100, status: "active", location: "Entrepôt B" },
  { name: "Housses de chaises", category: "Linge", quantity: 500, status: "active", location: "Entrepôt B" },
  
  # Équipement technique
  { name: "Système son JBL 5000W", category: "Sonorisation", quantity: 1, status: "active", location: "Régie" },
  { name: "Console de mixage Yamaha", category: "Sonorisation", quantity: 2, status: "active", location: "Régie" },
  { name: "Microphones sans fil Shure", category: "Sonorisation", quantity: 8, status: "active", location: "Régie" },
  { name: "Projecteur laser 10000 lumens", category: "Éclairage", quantity: 4, status: "active", location: "Régie" },
  { name: "Lyres LED", category: "Éclairage", quantity: 12, status: "active", location: "Régie" },
  { name: "Machine à fumée", category: "Effets", quantity: 2, status: "active", location: "Régie" },
  
  # Décoration
  { name: "Arche florale", category: "Décoration", quantity: 3, status: "active", location: "Entrepôt C" },
  { name: "Candélabres", category: "Décoration", quantity: 30, status: "active", location: "Entrepôt C" },
  { name: "Vases cristal", category: "Décoration", quantity: 50, status: "active", location: "Entrepôt C" },
  
  # Cuisine
  { name: "Chafing dish inox", category: "Restauration", quantity: 20, status: "active", location: "Cuisine" },
  { name: "Service vaisselle porcelaine", category: "Restauration", quantity: 600, status: "active", location: "Cuisine" }
]

materials_data.each do |mat_data|
  Material.find_or_create_by!(company_id: company.id, name: mat_data[:name]) do |mat|
    mat.category = mat_data[:category]
    mat.status = mat_data[:status]
    mat.location = mat_data[:location]
    mat.description = "#{mat_data[:name]} - Quantité: #{mat_data[:quantity]}"
    mat.purchase_date = Faker::Date.between(from: 3.years.ago, to: 6.months.ago)
    mat.next_maintenance_date = Faker::Date.between(from: Date.today, to: 6.months.from_now)
    mat.maintenance_interval_days = [30, 60, 90, 180, 365].sample
  end
end

puts "✔️ #{Material.count} matériels créés"

# === Seed Fournisseurs ===
puts "🚚 Seeding Fournisseurs..."

suppliers_data = [
  { name: "Fleurs Jasmin", category: "Fleuriste", email: "contact@fleursjasmin.tn", phone: "+21671234567", city: "Sfax" },
  { name: "Traiteur El Walima", category: "Traiteur", email: "info@elwalima.tn", phone: "+21671234568", city: "Sfax" },
  { name: "Location Matériel Événementiel", category: "Location", email: "contact@lme.tn", phone: "+21671234569", city: "Tunis" },
  { name: "Sono Pro Tunisie", category: "Technique", email: "info@sonopro.tn", phone: "+21671234570", city: "Sousse" },
  { name: "Pâtisserie El Nour", category: "Pâtisserie", email: "commandes@elnour.tn", phone: "+21671234571", city: "Sfax" }
]

suppliers_data.each do |sup_data|
  Supplier.find_or_create_by!(company_id: company.id, email: sup_data[:email]) do |sup|
    sup.name = sup_data[:name]
    sup.category = sup_data[:category]
    sup.phone_number = sup_data[:phone]
    sup.city = sup_data[:city]
    sup.country = "Tunisie"
    sup.status = "active"
  end
end

puts "✔️ #{Supplier.count} fournisseurs créés"

# === Seed Venues (Salles & Espaces à louer) ===
puts "🏛️ Seeding Venues (Salles & Espaces à louer)..."

venues_data = [
  {
    name: "Salle El Firdaws",
    description: "Grande salle de réception luxueuse avec lustres en cristal, idéale pour mariages et grandes cérémonies. Décoration style royal avec dorures et marbres.",
    venue_type: "salle",
    capacity_min: 200,
    capacity_max: 500,
    surface_area: 800.0,
    hourly_rate: 500.0,
    daily_rate: 3500.0,
    weekend_rate: 5000.0,
    location: "Bâtiment Principal - RDC",
    floor: "Rez-de-chaussée",
    amenities: ["Climatisation", "Sonorisation", "Éclairage LED", "Scène", "Vestiaire", "Toilettes privées", "Cuisine attenante"],
    is_indoor: true,
    is_outdoor: false,
    has_catering: true,
    has_parking: true,
    parking_capacity: 150,
    has_sound_system: true,
    has_lighting: true,
    has_air_conditioning: true,
    has_stage: true,
    status: "available"
  },
  {
    name: "Salle Yasmine",
    description: "Salle de taille moyenne au style moderne, parfaite pour fiançailles, anniversaires et petites réceptions. Ambiance chaleureuse et intime.",
    venue_type: "salle",
    capacity_min: 50,
    capacity_max: 150,
    surface_area: 300.0,
    hourly_rate: 250.0,
    daily_rate: 1500.0,
    weekend_rate: 2500.0,
    location: "Bâtiment Principal - 1er étage",
    floor: "1er étage",
    amenities: ["Climatisation", "Sonorisation", "Éclairage", "Vestiaire", "Toilettes"],
    is_indoor: true,
    is_outdoor: false,
    has_catering: true,
    has_parking: true,
    parking_capacity: 50,
    has_sound_system: true,
    has_lighting: true,
    has_air_conditioning: true,
    has_stage: false,
    status: "available"
  },
  {
    name: "Jardin El Nakhil",
    description: "Magnifique jardin extérieur avec palmiers et fontaines, idéal pour cérémonies en plein air, cocktails et réceptions d'été. Vue panoramique et espace photo.",
    venue_type: "jardin",
    capacity_min: 100,
    capacity_max: 400,
    surface_area: 1500.0,
    hourly_rate: 400.0,
    daily_rate: 2500.0,
    weekend_rate: 4000.0,
    location: "Extérieur - Côté Est",
    floor: "Extérieur",
    amenities: ["Éclairage décoratif", "Fontaine", "Espace photo", "Tente option", "Toilettes", "Espace cocktail"],
    is_indoor: false,
    is_outdoor: true,
    has_catering: true,
    has_parking: true,
    parking_capacity: 100,
    has_sound_system: false,
    has_lighting: true,
    has_air_conditioning: false,
    has_stage: false,
    status: "available"
  },
  {
    name: "Terrasse Panoramique",
    description: "Terrasse sur le toit avec vue exceptionnelle sur la ville, parfaite pour soirées VIP, cocktails et événements exclusifs au coucher du soleil.",
    venue_type: "rooftop",
    capacity_min: 30,
    capacity_max: 100,
    surface_area: 200.0,
    hourly_rate: 300.0,
    daily_rate: 1800.0,
    weekend_rate: 2800.0,
    location: "Bâtiment Principal - Toit",
    floor: "3ème étage (Rooftop)",
    amenities: ["Bar", "Coin lounge", "Éclairage ambiance", "Parasols", "Vue panoramique"],
    is_indoor: false,
    is_outdoor: true,
    has_catering: true,
    has_parking: true,
    parking_capacity: 30,
    has_sound_system: true,
    has_lighting: true,
    has_air_conditioning: false,
    has_stage: false,
    status: "available"
  },
  {
    name: "Espace VIP Lounge",
    description: "Salon privé élégant pour réunions de famille, petits événements intimes ou espace d'honneur pour mariés et invités VIP.",
    venue_type: "salle",
    capacity_min: 10,
    capacity_max: 40,
    surface_area: 80.0,
    hourly_rate: 150.0,
    daily_rate: 800.0,
    weekend_rate: 1200.0,
    location: "Bâtiment Principal - 1er étage",
    floor: "1er étage",
    amenities: ["Climatisation", "Canapés cuir", "Écran TV", "Mini bar", "Toilettes privées"],
    is_indoor: true,
    is_outdoor: false,
    has_catering: true,
    has_parking: true,
    parking_capacity: 15,
    has_sound_system: true,
    has_lighting: true,
    has_air_conditioning: true,
    has_stage: false,
    status: "available"
  },
  {
    name: "Espace Piscine",
    description: "Espace piscine avec terrasse aménagée pour pool parties, événements d'été et réceptions décontractées.",
    venue_type: "piscine",
    capacity_min: 20,
    capacity_max: 80,
    surface_area: 400.0,
    hourly_rate: 350.0,
    daily_rate: 2000.0,
    weekend_rate: 3000.0,
    location: "Extérieur - Côté Ouest",
    floor: "Extérieur",
    amenities: ["Piscine", "Transats", "Bar d'été", "Vestiaires", "Douches", "DJ booth"],
    is_indoor: false,
    is_outdoor: true,
    has_catering: true,
    has_parking: true,
    parking_capacity: 40,
    has_sound_system: true,
    has_lighting: true,
    has_air_conditioning: false,
    has_stage: false,
    status: "available"
  }
]

venues_data.each do |venue_data|
  Venue.find_or_create_by!(company_id: company.id, name: venue_data[:name]) do |venue|
    venue.description = venue_data[:description]
    venue.venue_type = venue_data[:venue_type]
    venue.capacity_min = venue_data[:capacity_min]
    venue.capacity_max = venue_data[:capacity_max]
    venue.surface_area = venue_data[:surface_area]
    venue.hourly_rate = venue_data[:hourly_rate]
    venue.daily_rate = venue_data[:daily_rate]
    venue.weekend_rate = venue_data[:weekend_rate]
    venue.location = venue_data[:location]
    venue.floor = venue_data[:floor]
    venue.amenities = venue_data[:amenities]
    venue.is_indoor = venue_data[:is_indoor]
    venue.is_outdoor = venue_data[:is_outdoor]
    venue.has_catering = venue_data[:has_catering]
    venue.has_parking = venue_data[:has_parking]
    venue.parking_capacity = venue_data[:parking_capacity]
    venue.has_sound_system = venue_data[:has_sound_system]
    venue.has_lighting = venue_data[:has_lighting]
    venue.has_air_conditioning = venue_data[:has_air_conditioning]
    venue.has_stage = venue_data[:has_stage]
    venue.status = venue_data[:status]
  end
end

puts "✔️ #{Venue.count} salles/espaces créés"

# === Résumé Final ===
puts "\n" + "=" * 50
puts "🎉 SEEDING TERMINÉ AVEC SUCCÈS!"
puts "=" * 50
puts "📊 Résumé:"
puts "   - Catégories: #{Categorie.count}"
puts "   - Utilisateurs: #{User.count}"
puts "   - Salles des fêtes (Companies): #{Company.count}"
puts "   - Départements: #{Department.count}"
puts "   - Employés: #{Employee.count}"
puts "   - Matériels: #{Material.count}"
puts "   - Fournisseurs: #{Supplier.count}"
puts "   - Venues (Salles & Espaces): #{Venue.count}"
puts "=" * 50
puts "\n🔐 Identifiants de connexion:"
puts "   Superadmin: superadmin@sallapro.tn / 12345678"
puts "   Admin: admin@sallapro.tn / 12345678"
puts "=" * 50
puts "\n🏛️ Salles disponibles:"
Venue.all.each do |venue|
  puts "   - #{venue.name} (#{venue.venue_type_label}) - Capacité: #{venue.capacity_range}"
end
puts "=" * 50
