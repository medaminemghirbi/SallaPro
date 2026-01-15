# db/seeds/employees_seed.rb
# Run this seed file with: rails runner db/seeds/employees_seed.rb

# Helper method for skills - defined at the top
def generate_skills(department_code)
  skills_by_dept = {
    "DG" => ["Leadership", "Management", "Strategy", "Communication", "Decision Making"],
    "RH" => ["Recruitment", "Training", "Labor Law", "Payroll", "Employee Relations"],
    "COM" => ["Sales", "Negotiation", "CRM", "Customer Relations", "Presentation"],
    "TECH" => ["Maintenance", "Repair", "Installation", "Technical Support", "Troubleshooting"],
    "LOG" => ["Inventory Management", "Logistics", "Supply Chain", "Warehousing", "Delivery"],
    "FIN" => ["Accounting", "Financial Analysis", "Excel", "Budgeting", "Reporting"]
  }
  
  dept_skills = skills_by_dept[department_code] || []
  dept_skills.sample(rand(2..4))
end

puts "🗑️  Cleaning old employee data..."

# Get the first company (admin's company)
company = Company.first

unless company
  puts "❌ No company found. Please run main seeds first."
  exit
end

puts "📦 Working with company: #{company.name}"

# Remove old employees (except default admin) using delete_all to skip callbacks
employee_ids = Employee.where(company_id: company.id).where(default_admin: false).pluck(:id)
if employee_ids.any?
  # Clean up attachments first
  ActiveStorage::Attachment.where(record_type: 'User', record_id: employee_ids).delete_all
  # Delete employees
  Employee.where(id: employee_ids).delete_all
end

# Remove old teams and departments using delete_all
Team.where(company_id: company.id).delete_all
Department.where(company_id: company.id).delete_all

puts "✅ Old data cleaned"

# =============== CREATE DEPARTMENTS ===============
puts "🏢 Creating departments..."

departments_data = [
  { name: "Direction Générale", code: "DG", description: "Direction et management de l'entreprise", color: "#6366f1" },
  { name: "Ressources Humaines", code: "RH", description: "Gestion du personnel et recrutement", color: "#22c55e" },
  { name: "Commercial", code: "COM", description: "Ventes et relations clients", color: "#f59e0b" },
  { name: "Technique", code: "TECH", description: "Services techniques et maintenance", color: "#3b82f6" },
  { name: "Logistique", code: "LOG", description: "Gestion des stocks et livraisons", color: "#8b5cf6" },
  { name: "Finance", code: "FIN", description: "Comptabilité et gestion financière", color: "#ef4444" }
]

departments = {}
departments_data.each do |dept_data|
  dept = Department.create!(
    company: company,
    name: dept_data[:name],
    code: dept_data[:code],
    description: dept_data[:description],
    color: dept_data[:color],
    active: true
  )
  departments[dept_data[:code]] = dept
  puts "  ✔️ #{dept.name}"
end

puts "✅ #{departments.count} departments created"

# =============== CREATE TEAMS ===============
puts "👥 Creating teams..."

teams_data = [
  { name: "Équipe Direction", code: "DIR-01", department: "DG", color: "#6366f1", description: "Équipe de direction" },
  { name: "Recrutement", code: "RH-REC", department: "RH", color: "#22c55e", description: "Équipe de recrutement" },
  { name: "Formation", code: "RH-FOR", department: "RH", color: "#10b981", description: "Formation et développement" },
  { name: "Ventes Nord", code: "COM-N", department: "COM", color: "#f59e0b", description: "Équipe commerciale zone Nord" },
  { name: "Ventes Sud", code: "COM-S", department: "COM", color: "#fbbf24", description: "Équipe commerciale zone Sud" },
  { name: "Maintenance", code: "TECH-M", department: "TECH", color: "#3b82f6", description: "Équipe maintenance" },
  { name: "Installation", code: "TECH-I", department: "TECH", color: "#0ea5e9", description: "Équipe installation" },
  { name: "Entrepôt", code: "LOG-E", department: "LOG", color: "#8b5cf6", description: "Gestion entrepôt" },
  { name: "Livraisons", code: "LOG-L", department: "LOG", color: "#a855f7", description: "Équipe livraisons" },
  { name: "Comptabilité", code: "FIN-C", department: "FIN", color: "#ef4444", description: "Service comptabilité" }
]

teams = {}
teams_data.each do |team_data|
  dept = departments[team_data[:department]]
  team = Team.create!(
    company: company,
    department: dept,
    name: team_data[:name],
    code: team_data[:code],
    description: team_data[:description],
    color: team_data[:color],
    active: true
  )
  teams[team_data[:code]] = team
  puts "  ✔️ #{team.name} (#{dept.name})"
end

puts "✅ #{teams.count} teams created"

# =============== CREATE EMPLOYEES ===============
puts "👤 Creating employees..."

employees_data = [
  # Direction
  { firstname: "Sophie", lastname: "Martin", email: "sophie.martin@company.com", position: "Directrice Générale", department: "DG", team: "DIR-01", status: "active", contract_type: "full_time", salary: 8500 },
  { firstname: "Pierre", lastname: "Dubois", email: "pierre.dubois@company.com", position: "Directeur Adjoint", department: "DG", team: "DIR-01", status: "active", contract_type: "full_time", salary: 6500 },
  
  # RH
  { firstname: "Marie", lastname: "Bernard", email: "marie.bernard@company.com", position: "Responsable RH", department: "RH", team: "RH-REC", status: "active", contract_type: "full_time", salary: 4500 },
  { firstname: "Julien", lastname: "Petit", email: "julien.petit@company.com", position: "Chargé de recrutement", department: "RH", team: "RH-REC", status: "active", contract_type: "full_time", salary: 3200 },
  { firstname: "Claire", lastname: "Moreau", email: "claire.moreau@company.com", position: "Formatrice", department: "RH", team: "RH-FOR", status: "on_leave", contract_type: "full_time", salary: 3000 },
  
  # Commercial
  { firstname: "Thomas", lastname: "Robert", email: "thomas.robert@company.com", position: "Directeur Commercial", department: "COM", team: "COM-N", status: "active", contract_type: "full_time", salary: 5000 },
  { firstname: "Emma", lastname: "Richard", email: "emma.richard@company.com", position: "Commerciale Senior", department: "COM", team: "COM-N", status: "active", contract_type: "full_time", salary: 3500 },
  { firstname: "Lucas", lastname: "Durand", email: "lucas.durand@company.com", position: "Commercial", department: "COM", team: "COM-N", status: "active", contract_type: "full_time", salary: 2800 },
  { firstname: "Léa", lastname: "Leroy", email: "lea.leroy@company.com", position: "Commerciale", department: "COM", team: "COM-S", status: "active", contract_type: "full_time", salary: 2800 },
  { firstname: "Hugo", lastname: "Simon", email: "hugo.simon@company.com", position: "Commercial Junior", department: "COM", team: "COM-S", status: "active", contract_type: "contract", salary: 2200 },
  { firstname: "Camille", lastname: "Laurent", email: "camille.laurent@company.com", position: "Stagiaire Commercial", department: "COM", team: "COM-S", status: "active", contract_type: "intern", salary: 800 },
  
  # Technique
  { firstname: "Antoine", lastname: "Michel", email: "antoine.michel@company.com", position: "Responsable Technique", department: "TECH", team: "TECH-M", status: "active", contract_type: "full_time", salary: 4800 },
  { firstname: "Nicolas", lastname: "Garcia", email: "nicolas.garcia@company.com", position: "Technicien Senior", department: "TECH", team: "TECH-M", status: "active", contract_type: "full_time", salary: 3200 },
  { firstname: "Maxime", lastname: "David", email: "maxime.david@company.com", position: "Technicien", department: "TECH", team: "TECH-M", status: "inactive", contract_type: "full_time", salary: 2600 },
  { firstname: "Alexandre", lastname: "Bertrand", email: "alexandre.bertrand@company.com", position: "Installateur", department: "TECH", team: "TECH-I", status: "active", contract_type: "full_time", salary: 2800 },
  { firstname: "Romain", lastname: "Roux", email: "romain.roux@company.com", position: "Installateur", department: "TECH", team: "TECH-I", status: "active", contract_type: "part_time", salary: 1800 },
  
  # Logistique
  { firstname: "Vincent", lastname: "Vincent", email: "vincent.vincent@company.com", position: "Responsable Logistique", department: "LOG", team: "LOG-E", status: "active", contract_type: "full_time", salary: 4200 },
  { firstname: "Quentin", lastname: "Fournier", email: "quentin.fournier@company.com", position: "Gestionnaire Stock", department: "LOG", team: "LOG-E", status: "active", contract_type: "full_time", salary: 2500 },
  { firstname: "Yann", lastname: "Girard", email: "yann.girard@company.com", position: "Livreur", department: "LOG", team: "LOG-L", status: "active", contract_type: "full_time", salary: 2200 },
  { firstname: "Kevin", lastname: "Andre", email: "kevin.andre@company.com", position: "Livreur", department: "LOG", team: "LOG-L", status: "on_leave", contract_type: "full_time", salary: 2200 },
  
  # Finance
  { firstname: "Isabelle", lastname: "Lefevre", email: "isabelle.lefevre@company.com", position: "Directrice Financière", department: "FIN", team: "FIN-C", status: "active", contract_type: "full_time", salary: 5500 },
  { firstname: "François", lastname: "Mercier", email: "francois.mercier@company.com", position: "Comptable", department: "FIN", team: "FIN-C", status: "active", contract_type: "full_time", salary: 3200 },
  { firstname: "Nathalie", lastname: "Blanc", email: "nathalie.blanc@company.com", position: "Aide Comptable", department: "FIN", team: "FIN-C", status: "terminated", contract_type: "contract", salary: 2400 }
]

employee_count = 0
employees_data.each_with_index do |emp_data, index|
  dept = departments[emp_data[:department]]
  team = teams[emp_data[:team]]
  hire_date = Date.today - rand(30..1825).days # Random hire date in last 5 years
  
  employee = Employee.new(
    email: emp_data[:email],
    firstname: emp_data[:firstname],
    lastname: emp_data[:lastname],
    password: "password123",
    password_confirmation: "password123",
    type: "Employee",
    company: company,
    department: dept,
    team: team,
    position: emp_data[:position],
    status: emp_data[:status],
    contract_type: emp_data[:contract_type],
    salary: emp_data[:salary],
    hire_date: hire_date,
    employee_id: "EMP-#{(index + 1).to_s.rjust(4, '0')}",
    phone_number: "+216#{rand(20000000..99999999)}",
    birthday: Date.new(rand(1970..2000), rand(1..12), rand(1..28)),
    gender: ["male", "female"].sample,
    civil_status: ["Mr", "Mme", "Mrs"].sample,
    confirmed_at: Time.zone.now,
    skills: generate_skills(emp_data[:department])
  )
  
  if employee.save
    employee_count += 1
    puts "  ✔️ #{employee.full_name} - #{employee.position} (#{dept.name})"
  else
    puts "  ❌ Failed to create #{emp_data[:firstname]} #{emp_data[:lastname]}: #{employee.errors.full_messages.join(', ')}"
  end
end

puts "✅ #{employee_count} employees created"

# =============== ASSIGN MANAGERS/LEADERS ===============
puts "👔 Assigning department managers and team leaders..."

# Assign department managers
manager_assignments = {
  "DG" => "sophie.martin@company.com",
  "RH" => "marie.bernard@company.com",
  "COM" => "thomas.robert@company.com",
  "TECH" => "antoine.michel@company.com",
  "LOG" => "vincent.vincent@company.com",
  "FIN" => "isabelle.lefevre@company.com"
}

manager_assignments.each do |dept_code, email|
  dept = departments[dept_code]
  manager = Employee.find_by(email: email)
  if dept && manager
    dept.update(manager: manager)
    puts "  ✔️ #{manager.full_name} → Manager of #{dept.name}"
  end
end

# Assign team leaders
leader_assignments = {
  "DIR-01" => "sophie.martin@company.com",
  "RH-REC" => "marie.bernard@company.com",
  "RH-FOR" => "claire.moreau@company.com",
  "COM-N" => "thomas.robert@company.com",
  "COM-S" => "lea.leroy@company.com",
  "TECH-M" => "antoine.michel@company.com",
  "TECH-I" => "alexandre.bertrand@company.com",
  "LOG-E" => "vincent.vincent@company.com",
  "LOG-L" => "yann.girard@company.com",
  "FIN-C" => "isabelle.lefevre@company.com"
}

leader_assignments.each do |team_code, email|
  team = teams[team_code]
  leader = Employee.find_by(email: email)
  if team && leader
    team.update(leader: leader)
    puts "  ✔️ #{leader.full_name} → Leader of #{team.name}"
  end
end

puts "✅ Managers and leaders assigned"

puts ""
puts "=" * 50
puts "🎉 SEED COMPLETED SUCCESSFULLY!"
puts "=" * 50
puts "📊 Summary:"
puts "   - #{Department.where(company: company).count} Departments"
puts "   - #{Team.where(company: company).count} Teams"
puts "   - #{Employee.where(company: company).count} Employees"
puts "   - Active: #{Employee.where(company: company, status: 'active').count}"
puts "   - On Leave: #{Employee.where(company: company, status: 'on_leave').count}"
puts "   - Inactive: #{Employee.where(company: company, status: 'inactive').count}"
puts "   - Terminated: #{Employee.where(company: company, status: 'terminated').count}"
puts "=" * 50
