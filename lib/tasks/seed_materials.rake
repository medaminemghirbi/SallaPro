# frozen_string_literal: true

namespace :materials do
  desc "Seed materials and notifications for testing"
  task seed: :environment do
    puts "🔧 Seeding Materials and Notifications..."

    # Find the admin and company
    admin = Admin.find_by(email: "admin@farhatn.com")
    unless admin
      puts "❌ Admin not found. Please run db:seed first."
      exit
    end

    company = Company.find_by(user_id: admin.id)
    unless company
      puts "❌ Company not found. Please run db:seed first."
      exit
    end

    # Clear existing materials and notifications for this company
    Material.where(company_id: company.id).destroy_all
    Notification.where(user_id: admin.id).destroy_all

    puts "📦 Creating materials..."

    materials_data = [
      {
        name: "Ordinateur Dell XPS 15",
        description: "Laptop pour développement",
        serial_number: "DL-XPS-2024-001",
        brand: "Dell",
        model: "XPS 15 9530",
        category: "Informatique",
        status: "active",
        location: "Bureau 101",
        purchase_price: 2500.00,
        purchase_date: Date.current - 6.months,
        warranty_expiry_date: Date.current + 18.months,
        next_maintenance_date: Date.current + 60.days,
        maintenance_interval_days: 180
      },
      {
        name: "Imprimante HP LaserJet",
        description: "Imprimante laser couleur",
        serial_number: "HP-LJ-2024-002",
        brand: "HP",
        model: "LaserJet Pro M454dw",
        category: "Informatique",
        status: "active",
        location: "Salle de reprographie",
        purchase_price: 450.00,
        purchase_date: Date.current - 1.year,
        warranty_expiry_date: Date.current + 10.days, # Expiring soon!
        next_maintenance_date: Date.current + 5.days, # Due soon!
        maintenance_interval_days: 90
      },
      {
        name: "Climatiseur LG",
        description: "Climatiseur split 12000 BTU",
        serial_number: "LG-AC-2024-003",
        brand: "LG",
        model: "S12EQ",
        category: "Climatisation",
        status: "active",
        location: "Salle de réunion",
        purchase_price: 800.00,
        purchase_date: Date.current - 2.years,
        warranty_expiry_date: Date.current - 6.months, # Expired!
        next_maintenance_date: Date.current - 3.days, # Overdue!
        maintenance_interval_days: 365
      },
      {
        name: "Projecteur Epson",
        description: "Projecteur Full HD",
        serial_number: "EP-PJ-2024-004",
        brand: "Epson",
        model: "EB-FH52",
        category: "Audiovisuel",
        status: "in_maintenance",
        location: "Salle de conférence",
        purchase_price: 750.00,
        purchase_date: Date.current - 8.months,
        warranty_expiry_date: Date.current + 2.years,
        next_maintenance_date: nil,
        maintenance_interval_days: nil
      },
      {
        name: "Photocopieur Canon",
        description: "Photocopieur multifonction",
        serial_number: "CN-PC-2024-005",
        brand: "Canon",
        model: "imageRUNNER C3226i",
        category: "Informatique",
        status: "active",
        location: "Accueil",
        purchase_price: 3200.00,
        purchase_date: Date.current - 3.months,
        warranty_expiry_date: Date.current + 33.months,
        next_maintenance_date: Date.current + 1.day, # Due tomorrow!
        maintenance_interval_days: 120
      },
      {
        name: "Serveur Dell PowerEdge",
        description: "Serveur rack pour applications",
        serial_number: "DL-PE-2024-006",
        brand: "Dell",
        model: "PowerEdge R750",
        category: "Infrastructure",
        status: "active",
        location: "Salle serveur",
        purchase_price: 8500.00,
        purchase_date: Date.current - 4.months,
        warranty_expiry_date: Date.current + 32.months,
        next_maintenance_date: Date.current + 90.days,
        maintenance_interval_days: 90
      },
      {
        name: "Écran Samsung 27\"",
        description: "Moniteur 4K pour bureau",
        serial_number: "SM-MN-2024-007",
        brand: "Samsung",
        model: "U28R550",
        category: "Informatique",
        status: "retired",
        location: "Stock",
        purchase_price: 350.00,
        purchase_date: Date.current - 3.years,
        warranty_expiry_date: Date.current - 1.year,
        next_maintenance_date: nil,
        maintenance_interval_days: nil
      }
    ]

    created_materials = []
    materials_data.each do |data|
      material = Material.create!(data.merge(company_id: company.id))
      created_materials << material
      puts "  ✔️ Created: #{material.name}"
    end

    puts "\n📋 Creating maintenance records..."

    # Add some maintenance records
    maintenance_records_data = [
      {
        material: created_materials[0],
        maintenance_type: "preventive",
        status: "completed",
        scheduled_date: Date.current - 3.months,
        completed_date: Date.current - 3.months,
        description: "Nettoyage et mise à jour système",
        cost: 50.00,
        service_provider: "IT Services"
      },
      {
        material: created_materials[1],
        maintenance_type: "corrective",
        status: "completed",
        scheduled_date: Date.current - 1.month,
        completed_date: Date.current - 1.month,
        description: "Remplacement du toner",
        cost: 120.00,
        service_provider: "HP Support"
      },
      {
        material: created_materials[2],
        maintenance_type: "preventive",
        status: "scheduled",
        scheduled_date: Date.current - 3.days, # Overdue
        completed_date: nil,
        description: "Nettoyage des filtres",
        cost: nil,
        service_provider: "ClimaTech"
      },
      {
        material: created_materials[3],
        maintenance_type: "corrective",
        status: "in_progress",
        scheduled_date: Date.current - 5.days,
        completed_date: nil,
        description: "Remplacement de la lampe",
        cost: 200.00,
        service_provider: "Epson Service"
      }
    ]

    maintenance_records_data.each do |data|
      material = data.delete(:material)
      record = material.maintenance_records.create!(data.merge(performed_by_id: admin.id))
      puts "  ✔️ Created maintenance record for: #{material.name}"
    end

    puts "\n🔔 Creating notifications..."

    notifications_data = [
      {
        title: "Maintenance en retard - Climatiseur LG",
        message: "La maintenance du Climatiseur LG (LG-AC-2024-003) est en retard de 3 jours.",
        notification_type: "maintenance_overdue",
        priority: "urgent",
        status: "unread",
        notifiable: created_materials[2],
        action_url: "/admin/materials"
      },
      {
        title: "Maintenance à venir - Photocopieur Canon",
        message: "La maintenance du Photocopieur Canon (CN-PC-2024-005) est prévue pour demain.",
        notification_type: "maintenance_reminder",
        priority: "high",
        status: "unread",
        notifiable: created_materials[4],
        action_url: "/admin/materials"
      },
      {
        title: "Maintenance à venir - Imprimante HP",
        message: "La maintenance de l'Imprimante HP LaserJet est prévue dans 5 jours.",
        notification_type: "maintenance_reminder",
        priority: "normal",
        status: "unread",
        notifiable: created_materials[1],
        action_url: "/admin/materials"
      },
      {
        title: "Garantie expirée - Climatiseur LG",
        message: "La garantie du Climatiseur LG (LG-AC-2024-003) a expiré il y a 6 mois.",
        notification_type: "warranty_expiry",
        priority: "normal",
        status: "unread",
        notifiable: created_materials[2],
        action_url: "/admin/materials"
      },
      {
        title: "Garantie expire bientôt - Imprimante HP",
        message: "La garantie de l'Imprimante HP LaserJet expire dans 10 jours.",
        notification_type: "warranty_expiry",
        priority: "high",
        status: "unread",
        notifiable: created_materials[1],
        action_url: "/admin/materials"
      },
      {
        title: "Bienvenue sur SallaPro",
        message: "Bienvenue sur votre nouveau système de gestion. Explorez les fonctionnalités disponibles.",
        notification_type: "info",
        priority: "low",
        status: "read",
        notifiable: nil,
        action_url: nil
      }
    ]

    notifications_data.each do |data|
      notification = Notification.create!(data.merge(
        user_id: admin.id,
        company_id: company.id
      ))
      puts "  ✔️ Created notification: #{notification.title}"
    end

    puts "\n✅ Seeding complete!"
    puts "   📦 Materials: #{Material.where(company_id: company.id).count}"
    puts "   📋 Maintenance Records: #{MaintenanceRecord.joins(:material).where(materials: { company_id: company.id }).count}"
    puts "   🔔 Notifications: #{Notification.where(user_id: admin.id).count}"
    puts "   🔴 Unread Notifications: #{Notification.where(user_id: admin.id).unread.count}"
  end

  desc "Clear all materials and notifications"
  task clear: :environment do
    admin = Admin.find_by(email: "admin@farhatn.com")
    if admin
      company = Company.find_by(user_id: admin.id)
      if company
        Material.where(company_id: company.id).destroy_all
        Notification.where(user_id: admin.id).destroy_all
        puts "✅ Cleared all materials and notifications"
      end
    end
  end
end
