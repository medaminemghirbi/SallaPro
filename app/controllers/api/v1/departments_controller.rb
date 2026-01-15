require 'csv'

class Api::V1::DepartmentsController < ApplicationController
  before_action :set_company
  before_action :set_department, only: [:show, :update, :destroy]

  # GET /api/v1/companies/:company_id/departments
  def index
    @departments = @company.departments.includes(:manager)

    # Filter by active status
    if params[:active].present?
      @departments = @departments.where(active: params[:active] == 'true')
    end

    # Search
    if params[:search].present?
      @departments = @departments.search_by_term(params[:search])
    end

    # Sorting
    sort_column = params[:sort] || 'name'
    sort_direction = params[:direction] == 'desc' ? 'desc' : 'asc'
    @departments = @departments.order("#{sort_column} #{sort_direction}")

    render json: @departments, each_serializer: DepartmentSerializer
  end

  # GET /api/v1/companies/:company_id/departments/:id
  def show
    render json: @department, serializer: DepartmentSerializer
  end

  # POST /api/v1/companies/:company_id/departments
  def create
    @department = @company.departments.new(department_params)

    if @department.save
      render json: @department, serializer: DepartmentSerializer, status: :created
    else
      render json: { errors: @department.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/companies/:company_id/departments/:id
  def update
    if @department.update(department_params)
      render json: @department, serializer: DepartmentSerializer
    else
      render json: { errors: @department.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/companies/:company_id/departments/:id
  def destroy
    # Check if department has employees before deletion
    if @department.employees.exists?
      render json: { error: 'Cannot delete department with assigned employees' }, status: :unprocessable_entity
    else
      @department.destroy
      head :no_content
    end
  end

  # GET /api/v1/companies/:company_id/departments/stats
  def stats
    stats = {
      total: @company.departments.count,
      active: @company.departments.active.count,
      inactive: @company.departments.inactive.count,
      total_employees: @company.employees.where.not(department_id: nil).count
    }

    render json: stats
  end

  # GET /api/v1/companies/:company_id/departments/list
  def list
    departments = @company.departments.active.select(:id, :name, :code, :color)
    render json: departments
  end

  # GET /api/v1/companies/:company_id/departments/:id/employees
  def employees
    @department = @company.departments.find(params[:id])
    @employees = @department.employees

    render json: @employees.map { |e|
      {
        id: e.id,
        firstname: e.firstname,
        lastname: e.lastname,
        email: e.email,
        phone_number: e.phone_number,
        position: e.position,
        status: e.status,
        department_id: e.department_id,
        department_name: @department.name,
        contract_type: e.contract_type,
        hire_date: e.hire_date,
        avatar_url: e.avatar.attached? ? url_for(e.avatar) : nil
      }
    }
  end

  # POST /api/v1/companies/:company_id/departments/export
  def export
    @departments = @company.departments.includes(:manager)

    # Apply filters
    if params[:active].present?
      @departments = @departments.where(active: params[:active] == 'true')
    end

    if params[:search].present?
      @departments = @departments.search_by_term(params[:search])
    end

    # Filter by specific IDs if provided
    if params[:ids].present?
      @departments = @departments.where(id: params[:ids])
    end

    format = params[:format] || 'csv'
    
    case format.to_s.downcase
    when 'csv'
      send_csv_export
    when 'json'
      send_json_export
    when 'pdf'
      send_pdf_export
    else
      render json: { error: 'Invalid format. Supported formats: csv, json, pdf' }, status: :unprocessable_entity
    end
  end

  private

  def set_company
    @company = Company.find(params[:company_id])
  end

  def set_department
    @department = @company.departments.find(params[:id])
  end

  def department_params
    params.require(:department).permit(
      :name, :code, :description, :color, :active, :manager_id
    )
  end

  def send_csv_export
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Name', 'Code', 'Description', 'Color', 'Manager', 'Employees Count', 'Active', 'Created At']
      
      @departments.each do |department|
        csv << [
          department.id,
          department.name,
          department.code,
          department.description,
          department.color,
          department.manager_name,
          department.employees_count,
          department.active ? 'Yes' : 'No',
          department.created_at.strftime('%Y-%m-%d %H:%M')
        ]
      end
    end

    send_data csv_data,
              type: 'text/csv; charset=utf-8',
              disposition: "attachment; filename=departments_#{Date.today}.csv"
  end

  def send_json_export
    export_data = @departments.map do |department|
      {
        id: department.id,
        name: department.name,
        code: department.code,
        description: department.description,
        color: department.color,
        manager_name: department.manager_name,
        employees_count: department.employees_count,
        active: department.active,
        created_at: department.created_at
      }
    end

    send_data export_data.to_json,
              type: 'application/json; charset=utf-8',
              disposition: "attachment; filename=departments_#{Date.today}.json"
  end

  def send_pdf_export
    # For PDF, we'll generate a simple HTML that can be converted to PDF
    html_content = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Departments Export</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 20px; }
          h1 { color: #333; border-bottom: 2px solid #3b82f6; padding-bottom: 10px; }
          table { width: 100%; border-collapse: collapse; margin-top: 20px; }
          th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
          th { background-color: #3b82f6; color: white; }
          tr:nth-child(even) { background-color: #f9f9f9; }
          .badge { padding: 2px 8px; border-radius: 4px; font-size: 12px; }
          .active { background-color: #22c55e; color: white; }
          .inactive { background-color: #6b7280; color: white; }
          .color-badge { display: inline-block; width: 20px; height: 20px; border-radius: 4px; vertical-align: middle; }
        </style>
      </head>
      <body>
        <h1>Departments Export - #{@company.name}</h1>
        <p>Generated on: #{Time.current.strftime('%Y-%m-%d %H:%M')}</p>
        <p>Total Departments: #{@departments.count}</p>
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Code</th>
              <th>Manager</th>
              <th>Employees</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            #{@departments.map { |d| 
              "<tr>
                <td>#{d.name}</td>
                <td>#{d.code}</td>
                <td>#{d.manager_name || '-'}</td>
                <td>#{d.employees_count}</td>
                <td><span class='badge #{d.active ? 'active' : 'inactive'}'>#{d.active ? 'Active' : 'Inactive'}</span></td>
              </tr>"
            }.join}
          </tbody>
        </table>
      </body>
      </html>
    HTML

    send_data html_content,
              type: 'text/html; charset=utf-8',
              disposition: "attachment; filename=departments_#{Date.today}.html"
  end
end
