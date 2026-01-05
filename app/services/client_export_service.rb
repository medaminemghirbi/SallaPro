# frozen_string_literal: true

class ClientExportService
  attr_reader :clients, :format

  SUPPORTED_FORMATS = %w[csv pdf json world].freeze

  def initialize(clients, format = 'csv')
    @clients = clients
    @format = format.to_s.downcase
  end

  def self.call(clients, format)
    new(clients, format).export
  end

  def export
    return { error: 'Invalid format', status: :bad_request } unless valid_format?

    case format
    when 'csv'
      { data: generate_csv, filename: csv_filename, type: 'text/csv; charset=utf-8' }
    when 'pdf'
      { data: generate_pdf, filename: pdf_filename, type: 'application/pdf' }
    when 'json', 'world'
      { data: generate_json, filename: json_filename, type: 'application/json' }
    end
  end

  private

  def valid_format?
    SUPPORTED_FORMATS.include?(format)
  end

  def generate_csv
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << csv_headers

      clients.each do |client|
        csv << csv_row(client)
      end
    end
  end

  def generate_pdf
    require 'prawn'

    Prawn::Document.new do |doc|
      add_pdf_header(doc)
      add_pdf_table(doc)
      add_pdf_footer(doc)
    end.render
  end

  def generate_json
    clients.map do |client|
      {
        id: client.id,
        firstname: client.firstname,
        lastname: client.lastname,
        email: client.email,
        phone_number: client.phone_number,
        address: client.address,
        created_at: client.created_at
      }
    end.to_json
  end

  def csv_headers
    ['ID', 'First Name', 'Last Name', 'Email', 'Birthday', 'Phone Number', 'Address', 'Created At']
  end

  def csv_row(client)
    [
      client.id,
      client.firstname,
      client.lastname,
      client.email,
      client.birthday&.strftime('%Y-%m-%d'),
      client.phone_number,
      client.address,
      client.created_at.strftime('%Y-%m-%d %H:%M:%S')
    ]
  end

  def add_pdf_header(doc)
    doc.text 'Clients Export', size: 20, style: :bold
    doc.move_down 10
    doc.text "Generated on: #{Time.current.strftime('%B %d, %Y at %H:%M')}", size: 10
    doc.move_down 20
  end

  def add_pdf_table(doc)
    table_data = [['ID', 'Name', 'Email', 'Phone', 'Created']]

    clients.each do |client|
      table_data << [
        client.id,
        "#{client.firstname} #{client.lastname}",
        client.email,
        client.phone_number,
        client.created_at.strftime('%Y-%m-%d')
      ]
    end

    doc.table(table_data,
              header: true,
              width: doc.bounds.width,
              cell_style: { size: 9, padding: 5 }) do
      row(0).font_style = :bold
      row(0).background_color = 'DDDDDD'
    end
  end

  def add_pdf_footer(doc)
    doc.number_pages 'Page <page> of <total>',
                     at: [doc.bounds.right - 150, 0],
                     align: :right,
                     size: 10
  end

  def csv_filename
    "clients_#{Date.today}.csv"
  end

  def pdf_filename
    "clients_#{Date.today}.pdf"
  end

  def json_filename
    prefix = (format == 'world') ? 'clients_world' : 'clients'
    "#{prefix}_#{Date.today}.json"
  end
end
