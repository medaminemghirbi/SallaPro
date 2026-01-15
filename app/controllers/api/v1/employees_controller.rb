# frozen_string_literal: true

require 'csv'

module Api
  module V1
    class EmployeesController < ApplicationController
      before_action :authorize_request
      before_action :set_company, only: [:index, :show, :update, :stats, :departments_list, :positions], if: -> { params[:company_id].present? }
      before_action :set_employee, only: [:show, :update, :destroy]

      # GET /api/v1/employees OR /api/v1/companies/:company_id/employees
      def index
        @employees = if @company
          @company.employees.includes(:department)
        else
          Employee.all.includes(:department)
        end

        # Search
        if params[:search].present?
          @employees = @employees.search_by_term(params[:search])
        end

        # Filter by status
        @employees = @employees.by_status(params[:status]) if params[:status].present?

        # Filter by department
        @employees = @employees.by_department(params[:department_id]) if params[:department_id].present?

        # Sorting
        sort_column = params[:sort] || 'created_at'
        sort_direction = params[:direction] == 'asc' ? 'asc' : 'desc'
        @employees = @employees.order("#{sort_column} #{sort_direction}")

        render json: @employees, each_serializer: EmployeeSerializer, status: :ok
      end

      # GET /api/v1/companies/:company_id/employees (legacy - now handled by index)
      def company_employees
        @employees = @company.employees.includes(:department)

        # Search
        if params[:search].present?
          @employees = @employees.search_by_term(params[:search])
        end

        # Filter by status
        @employees = @employees.by_status(params[:status]) if params[:status].present?

        # Filter by department
        @employees = @employees.by_department(params[:department_id]) if params[:department_id].present?

        # Sorting
        sort_column = params[:sort] || 'created_at'
        sort_direction = params[:direction] == 'asc' ? 'asc' : 'desc'
        @employees = @employees.order("#{sort_column} #{sort_direction}")

        render json: @employees, each_serializer: EmployeeSerializer, status: :ok
      end

      # GET /api/v1/employees/:id
      def show
        render json: @employee, serializer: EmployeeSerializer, status: :ok
      end

      # POST /api/v1/employees
      def create
        ActiveRecord::Base.transaction do
          employee = User.new(employee_params.merge(type: 'Employee'))
          employee.password = '000000'
          employee.password_confirmation = '000000'
          employee.skip_confirmation!
          employee.save!

          attach_avatar(employee) if params[:avatar].present?

          render json: { employee: EmployeeSerializer.new(employee), message: 'Employee created successfully' }, status: :created
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages.first }, status: :unprocessable_entity
      end

      # PUT/PATCH /api/v1/employees/:id
      def update
        update_params = params.require(:employee).permit(
          :firstname, :lastname, :address, :phone_number, :birthday, :country,
          :position, :status, :department_id,
          :contract_type, :work_schedule, :salary, :hire_date,
          :emergency_contact_name, :emergency_contact_phone, :company_id,
          skills: []
        )
        
        if @employee.update(update_params)
          attach_avatar(@employee) if params[:avatar].present?
          
          render json: {
            message: 'Employee updated successfully',
            employee: EmployeeSerializer.new(@employee)
          }, status: :ok
        else
          render json: {
            error: 'Failed to update employee',
            details: @employee.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
      
      # DELETE /api/v1/employees/:id
      def destroy
        if @employee.destroy
          render json: {
            message: 'Employee deleted successfully'
          }, status: :ok
        else
          render json: {
            error: 'Failed to delete employee',
            details: @employee.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/companies/:company_id/employees/stats
      def stats
        employees = @company.employees

        stats = {
          total: employees.count,
          active: employees.active.count,
          inactive: employees.inactive.count,
          on_leave: employees.on_leave.count,
          terminated: employees.terminated.count,
          by_department: @company.departments.map do |dept|
            { id: dept.id, name: dept.name, count: employees.by_department(dept.id).count }
          end,
          by_contract: {
            full_time: employees.where(contract_type: 'full_time').count,
            part_time: employees.where(contract_type: 'part_time').count,
            contract: employees.where(contract_type: 'contract').count,
            intern: employees.where(contract_type: 'intern').count,
            freelance: employees.where(contract_type: 'freelance').count
          },
          recent_hires: employees.recent.count,
          unassigned: employees.where(department_id: nil).count
        }

        render json: stats
      end

      # GET /api/v1/companies/:company_id/employees/departments_list
      def departments_list
        departments = @company.departments.active.select(:id, :name, :code, :color).map do |dept|
          { id: dept.id, name: dept.name, code: dept.code, color: dept.color }
        end
        render json: departments
      end

      # GET /api/v1/companies/:company_id/employees/positions
      def positions
        positions = @company.employees.where.not(position: [nil, '']).distinct.pluck(:position)
        render json: positions
      end

      # POST /api/v1/employees/export
      def export
        format = params[:format] || 'csv'
        employee_ids = params[:employeeIds] || []
        filters = params[:filters] || {}

        # Get employees - either by IDs or with filters
        employees = if employee_ids.present? && employee_ids.any?
          Employee.where(id: employee_ids).includes(:department)
        else
          employees = Employee.includes(:department)
          
          # Apply filters
          if filters[:search].present?
            employees = employees.search_by_term(filters[:search])
          end
          if filters[:status].present?
            employees = employees.by_status(filters[:status])
          end
          if filters[:department_id].present?
            employees = employees.by_department(filters[:department_id])
          end
          
          employees
        end

        case format.to_s.downcase
        when 'csv'
          export_csv(employees)
        when 'json'
          export_json(employees)
        when 'pdf'
          export_pdf(employees)
        else
          render json: { error: 'Unsupported format' }, status: :unprocessable_entity
        end
      end

      private

      def export_csv(employees)
        csv_data = CSV.generate(headers: true, col_sep: ';') do |csv|
          csv << ['ID', 'First Name', 'Last Name', 'Email', 'Phone', 'Position', 'Department', 'Status', 'Contract Type', 'Hire Date', 'Country', 'Address']
          
          employees.each do |emp|
            csv << [
              emp.employee_id || emp.id,
              emp.firstname,
              emp.lastname,
              emp.email,
              emp.phone_number,
              emp.position,
              emp.department&.name,
              emp.status,
              emp.contract_type,
              emp.hire_date&.strftime('%Y-%m-%d'),
              emp.country,
              emp.address
            ]
          end
        end

        send_data csv_data,
          filename: "employees_#{Date.today.strftime('%Y%m%d')}.csv",
          type: 'text/csv; charset=utf-8',
          disposition: 'attachment'
      end

      def export_json(employees)
        data = employees.map do |emp|
          {
            id: emp.employee_id || emp.id,
            firstname: emp.firstname,
            lastname: emp.lastname,
            full_name: emp.full_name,
            email: emp.email,
            phone: emp.phone_number,
            position: emp.position,
            department: emp.department&.name,
            status: emp.status,
            contract_type: emp.contract_type,
            hire_date: emp.hire_date&.strftime('%Y-%m-%d'),
            country: emp.country,
            address: emp.address
          }
        end

        send_data data.to_json,
          filename: "employees_#{Date.today.strftime('%Y%m%d')}.json",
          type: 'application/json',
          disposition: 'attachment'
      end

      def export_pdf(employees)
        # Simple PDF generation using Prawn if available, otherwise return JSON
        begin
          require 'prawn'
          
          pdf = Prawn::Document.new(page_size: 'A4', page_layout: :landscape)
          
          pdf.text "Employee List", size: 20, style: :bold, align: :center
          pdf.text "Generated on #{Date.today.strftime('%B %d, %Y')}", size: 10, align: :center
          pdf.move_down 20
          
          table_data = [['Name', 'Email', 'Position', 'Department', 'Status', 'Hire Date']]
          
          employees.each do |emp|
            table_data << [
              emp.full_name,
              emp.email,
              emp.position || '-',
              emp.department&.name || '-',
              emp.status&.capitalize || '-',
              emp.hire_date&.strftime('%Y-%m-%d') || '-'
            ]
          end
          
          pdf.table(table_data, header: true, width: pdf.bounds.width) do
            row(0).font_style = :bold
            row(0).background_color = '4a5568'
            row(0).text_color = 'ffffff'
            cells.padding = 8
            cells.border_width = 0.5
          end
          
          send_data pdf.render,
            filename: "employees_#{Date.today.strftime('%Y%m%d')}.pdf",
            type: 'application/pdf',
            disposition: 'attachment'
        rescue LoadError
          # Prawn not available, fall back to JSON
          export_json(employees)
        end
      end

      def set_company
        @company = Company.find(params[:company_id])
      end

      def set_employee
        @employee = Employee.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Employee not found' }, status: :not_found
      end

      def employee_params
        params.permit(
          :firstname, :lastname, :email,
          :birthday, :address, :latitude, :longitude, :phone_number, :country,
          :position, :status, :department_id,
          :contract_type, :work_schedule, :salary, :hire_date,
          :emergency_contact_name, :emergency_contact_phone, :company_id,
          skills: []
        )
      end

      def attach_avatar(employee)
        employee.avatar.attach(params[:avatar])
      end
    end
  end
end
