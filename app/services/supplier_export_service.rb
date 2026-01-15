# frozen_string_literal: true

class SupplierExportService
  def self.call(suppliers, format)
    new(suppliers, format).call
  end

  def initialize(suppliers, format)
    @suppliers = suppliers
    @format = format&.downcase || 'csv'
  end

  def call
    case @format
    when 'csv'
      export_csv
    when 'json'
      export_json
    when 'pdf'
      export_pdf
    else
      { error: 'Invalid format', status: :unprocessable_entity }
    end
  end

  private

  def export_csv
    require 'csv'

    csv_data = CSV.generate(headers: true) do |csv|
      csv << csv_headers

      @suppliers.each do |supplier|
        csv << [
          supplier.unique_code,
          supplier.name,
          supplier.email,
          supplier.phone_number,
          supplier.contact_person,
          supplier.contact_email,
          supplier.contact_phone,
          supplier.address,
          supplier.city,
          supplier.country,
          supplier.postal_code,
          supplier.category,
          supplier.status,
          supplier.website,
          supplier.tax_id,
          supplier.payment_terms,
          supplier.description,
          supplier.created_at&.strftime('%Y-%m-%d %H:%M')
        ]
      end
    end

    {
      data: csv_data,
      filename: "suppliers_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
      type: 'text/csv; charset=utf-8'
    }
  end

  def export_json
    json_data = @suppliers.map do |supplier|
      {
        unique_code: supplier.unique_code,
        name: supplier.name,
        email: supplier.email,
        phone_number: supplier.phone_number,
        contact_person: supplier.contact_person,
        contact_email: supplier.contact_email,
        contact_phone: supplier.contact_phone,
        address: supplier.address,
        city: supplier.city,
        country: supplier.country,
        postal_code: supplier.postal_code,
        category: supplier.category,
        status: supplier.status,
        website: supplier.website,
        tax_id: supplier.tax_id,
        payment_terms: supplier.payment_terms,
        description: supplier.description,
        latitude: supplier.latitude,
        longitude: supplier.longitude,
        created_at: supplier.created_at&.iso8601
      }
    end

    {
      data: JSON.pretty_generate(json_data),
      filename: "suppliers_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json",
      type: 'application/json; charset=utf-8'
    }
  end

  def export_pdf
    # For PDF export, we'll generate a simple HTML table and convert to PDF
    # This is a placeholder - you may want to use a gem like Prawn or WickedPdf
    html_content = generate_pdf_html
    
    {
      data: html_content,
      filename: "suppliers_#{Time.current.strftime('%Y%m%d_%H%M%S')}.html",
      type: 'text/html; charset=utf-8'
    }
  end

  def csv_headers
    [
      'Code', 'Name', 'Email', 'Phone', 'Contact Person', 'Contact Email', 'Contact Phone',
      'Address', 'City', 'Country', 'Postal Code', 'Category', 'Status',
      'Website', 'Tax ID', 'Payment Terms', 'Description', 'Created At'
    ]
  end

  def generate_pdf_html
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Suppliers Export</title>
        <style>
          body { font-family: Arial, sans-serif; font-size: 12px; }
          table { width: 100%; border-collapse: collapse; margin-top: 20px; }
          th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
          th { background-color: #4a90d9; color: white; }
          tr:nth-child(even) { background-color: #f9f9f9; }
          h1 { color: #333; }
          .export-date { color: #666; font-size: 10px; }
        </style>
      </head>
      <body>
        <h1>Suppliers Export</h1>
        <p class="export-date">Generated on: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}</p>
        <table>
          <thead>
            <tr>
              <th>Code</th>
              <th>Name</th>
              <th>Email</th>
              <th>Phone</th>
              <th>Contact</th>
              <th>Address</th>
              <th>Category</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            #{@suppliers.map { |s| supplier_row_html(s) }.join}
          </tbody>
        </table>
      </body>
      </html>
    HTML
  end

  def supplier_row_html(supplier)
    <<~HTML
      <tr>
        <td>#{supplier.unique_code}</td>
        <td>#{supplier.name}</td>
        <td>#{supplier.email}</td>
        <td>#{supplier.phone_number}</td>
        <td>#{supplier.contact_person}</td>
        <td>#{supplier.full_address}</td>
        <td>#{supplier.category}</td>
        <td>#{supplier.status}</td>
      </tr>
    HTML
  end
end
