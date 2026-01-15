# frozen_string_literal: true

class VenueExportService
  attr_reader :venues, :format

  SUPPORTED_FORMATS = %w[csv pdf json].freeze

  def initialize(venues, format = 'csv')
    @venues = venues
    @format = format.to_s.downcase
  end

  def self.call(venues, format)
    new(venues, format).export
  end

  def export
    return { error: 'Invalid format', status: :bad_request } unless valid_format?

    case format
    when 'csv'
      { data: generate_csv, filename: csv_filename, type: 'text/csv; charset=utf-8' }
    when 'pdf'
      { data: generate_pdf, filename: pdf_filename, type: 'application/pdf' }
    when 'json'
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

      venues.each do |venue|
        csv << csv_row(venue)
      end
    end
  end

  def generate_pdf
    require 'prawn'

    Prawn::Document.new(page_layout: :landscape) do |doc|
      add_pdf_header(doc)
      add_pdf_table(doc)
      add_pdf_footer(doc)
    end.render
  end

  def generate_json
    venues.map do |venue|
      {
        id: venue.id,
        name: venue.name,
        description: venue.description,
        venue_type: venue.venue_type,
        venue_type_label: venue.venue_type_label,
        capacity_min: venue.capacity_min,
        capacity_max: venue.capacity_max,
        capacity_range: venue.capacity_range,
        surface_area: venue.surface_area,
        hourly_rate: venue.hourly_rate,
        daily_rate: venue.daily_rate,
        weekend_rate: venue.weekend_rate,
        location: venue.location,
        floor: venue.floor,
        amenities: venue.amenities_list,
        is_indoor: venue.is_indoor,
        is_outdoor: venue.is_outdoor,
        has_catering: venue.has_catering,
        has_parking: venue.has_parking,
        parking_capacity: venue.parking_capacity,
        has_sound_system: venue.has_sound_system,
        has_lighting: venue.has_lighting,
        has_air_conditioning: venue.has_air_conditioning,
        has_stage: venue.has_stage,
        status: venue.status,
        status_label: venue.status_label,
        created_at: venue.created_at
      }
    end.to_json
  end

  def csv_headers
    [
      'ID', 'Nom', 'Type', 'Capacité Min', 'Capacité Max', 'Surface (m²)',
      'Tarif Horaire (TND)', 'Tarif Journalier (TND)', 'Tarif Weekend (TND)',
      'Emplacement', 'Étage', 'Intérieur', 'Extérieur',
      'Traiteur', 'Parking', 'Places Parking', 'Sono', 'Éclairage',
      'Climatisation', 'Scène', 'Statut', 'Créé le'
    ]
  end

  def csv_row(venue)
    [
      venue.id,
      venue.name,
      venue.venue_type_label,
      venue.capacity_min,
      venue.capacity_max,
      venue.surface_area,
      venue.hourly_rate,
      venue.daily_rate,
      venue.weekend_rate,
      venue.location,
      venue.floor,
      venue.is_indoor ? 'Oui' : 'Non',
      venue.is_outdoor ? 'Oui' : 'Non',
      venue.has_catering ? 'Oui' : 'Non',
      venue.has_parking ? 'Oui' : 'Non',
      venue.parking_capacity,
      venue.has_sound_system ? 'Oui' : 'Non',
      venue.has_lighting ? 'Oui' : 'Non',
      venue.has_air_conditioning ? 'Oui' : 'Non',
      venue.has_stage ? 'Oui' : 'Non',
      venue.status_label,
      venue.created_at.strftime('%Y-%m-%d %H:%M:%S')
    ]
  end

  def add_pdf_header(doc)
    doc.text 'Liste des Salles & Espaces', size: 20, style: :bold
    doc.move_down 10
    doc.text "Généré le: #{Time.current.strftime('%d/%m/%Y à %H:%M')}", size: 10
    doc.move_down 20
  end

  def add_pdf_table(doc)
    table_data = [['Nom', 'Type', 'Capacité', 'Tarif/jour', 'Emplacement', 'Statut']]

    venues.each do |venue|
      table_data << [
        venue.name,
        venue.venue_type_label,
        venue.capacity_range,
        "#{venue.daily_rate} TND",
        venue.location || '-',
        venue.status_label
      ]
    end

    doc.table(table_data, header: true, width: doc.bounds.width) do
      row(0).font_style = :bold
      row(0).background_color = 'DDDDDD'
      cells.borders = [:bottom]
      cells.padding = [8, 5]
    end
  end

  def add_pdf_footer(doc)
    doc.move_down 20
    doc.text "Total: #{venues.count} salle(s)/espace(s)", size: 10, style: :italic
  end

  def csv_filename
    "venues_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"
  end

  def pdf_filename
    "venues_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.pdf"
  end

  def json_filename
    "venues_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json"
  end
end
