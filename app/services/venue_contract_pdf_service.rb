# frozen_string_literal: true

class VenueContractPdfService
  include ActionView::Helpers::NumberHelper

  def initialize(contract)
    @contract = contract
    @currency = detect_currency
  end
  def detect_currency
    address = @contract.company&.admin&.address.to_s
    country = detect_country_from_address(address)
    case country
    when 'Tunisia', 'Tunisie'
      'TND'
    when 'France'
      '€'
    else
      '€'
    end
  end

  def detect_country_from_address(address)
    return nil if address.blank?
    result = Geocoder.search(address)&.first
    result&.country
  rescue
    nil
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 40) do |pdf|
      # Header
      setup_fonts(pdf)
      render_header(pdf)
      
      # Contract info
      render_contract_info(pdf)
      
      # Parties
      render_parties(pdf)
      
      # Event details
      render_event_details(pdf)
      
      # Pricing
      render_pricing(pdf)
      
      # Terms and conditions
      render_terms(pdf)
      
      # Signatures
      render_signatures(pdf)
      
      # Footer
      render_footer(pdf)
    end.render
  end

  private

  def setup_fonts(pdf)
    pdf.font_families.update(
      'DejaVu' => {
        normal: Rails.root.join('app/assets/fonts/DejaVuSans.ttf').to_s,
        bold: Rails.root.join('app/assets/fonts/DejaVuSans-Bold.ttf').to_s
      }
    )
    pdf.font 'DejaVu'
  rescue
    pdf.font 'Helvetica'
  end

  def render_header(pdf)
    title = @contract.status == 'devis' ? 'DEVIS' : 'CONTRAT DE LOCATION'
    
    pdf.text title, size: 24, style: :bold, align: :center
    pdf.move_down 5
    pdf.text "N° #{@contract.contract_number}", size: 12, align: :center, color: '666666'
    pdf.move_down 20
    pdf.stroke_horizontal_rule
    pdf.move_down 15
  end

  def render_contract_info(pdf)
    pdf.text "Date d'émission: #{I18n.l(@contract.created_at.to_date, format: :long)}", size: 10
    
    if @contract.valid_until.present?
      pdf.text "Valide jusqu'au: #{I18n.l(@contract.valid_until, format: :long)}", size: 10
    end
    
    pdf.text "Statut: #{@contract.status_label}", size: 10
    pdf.move_down 15
  end

  def render_parties(pdf)
    pdf.text 'PARTIES', size: 14, style: :bold
    pdf.move_down 10

    # Company info
    company = @contract.company
    pdf.text 'LE LOUEUR:', size: 11, style: :bold
    pdf.text company.name, size: 10
    pdf.text company.billing_address.to_s, size: 10 if company.billing_address.present?
    pdf.text "Tél: #{company.phone_number}", size: 10 if company.phone_number.present?
    pdf.move_down 10

    # Client info
    client = @contract.client
    pdf.text 'LE LOCATAIRE:', size: 11, style: :bold
    pdf.text "#{client.firstname} #{client.lastname}", size: 10
    pdf.text client.email, size: 10
    pdf.text "Tél: #{client.phone_number}", size: 10 if client.phone_number.present?
    pdf.text client.address.to_s, size: 10 if client.address.present?
    pdf.move_down 15
  end

  def render_event_details(pdf)
    pdf.text 'OBJET DE LA LOCATION', size: 14, style: :bold
    pdf.move_down 10

    venue = @contract.venue
    
    details = [
      ['Salle / Espace', venue.name],
      ['Type', venue.venue_type_label],
      ['Localisation', venue.location.to_s],
      ['Capacité', "#{venue.capacity_max} personnes"],
      ['Type d\'événement', @contract.event_type_label.to_s],
      ['Nombre d\'invités prévu', @contract.expected_guests.to_s]
    ]

    if @contract.event_start_date && @contract.event_end_date
      details << ['Date de début', I18n.l(@contract.event_start_date, format: :long)]
      details << ['Date de fin', I18n.l(@contract.event_end_date, format: :long)]
      details << ['Durée', "#{@contract.duration_days} jour(s)"]
    end

    pdf.table(details, width: pdf.bounds.width, cell_style: { size: 10, padding: 5 }) do
      column(0).font_style = :bold
      column(0).width = 150
    end

    if @contract.special_requests.present?
      pdf.move_down 10
      pdf.text 'Demandes spéciales:', size: 11, style: :bold
      pdf.text @contract.special_requests, size: 10
    end

    pdf.move_down 15
  end

  def render_pricing(pdf)
    pdf.text 'CONDITIONS FINANCIÈRES', size: 14, style: :bold
    pdf.move_down 10

    pricing_data = [
      ['Description', 'Montant']
    ]

    pricing_data << ['Prix de base', format_price(@contract.base_price)]
    
    if @contract.discount_percent.to_f > 0
      pricing_data << ["Remise (#{@contract.discount_percent}%)", "- #{format_price(@contract.base_price * @contract.discount_percent / 100)}"]
    elsif @contract.discount_amount.to_f > 0
      pricing_data << ['Remise', "- #{format_price(@contract.discount_amount)}"]
    end

    if @contract.selected_options.present? && @contract.selected_options.any?
      @contract.selected_options.each do |option|
        pricing_data << [option['name'].to_s, format_price(option['price'])]
      end
    end

    pricing_data << ["TVA (#{@contract.tax_rate}%)", format_price(@contract.tax_amount)]
    pricing_data << ['TOTAL TTC', format_price(@contract.total_amount)]

    if @contract.deposit_amount.to_f > 0
      pricing_data << ['Acompte demandé', format_price(@contract.deposit_amount)]
      pricing_data << ['Solde à régler', format_price(@contract.total_amount.to_f - @contract.deposit_amount.to_f)]
    end

    pdf.table(pricing_data, width: pdf.bounds.width, cell_style: { size: 10, padding: 8 }) do
      row(0).font_style = :bold
      row(0).background_color = 'EEEEEE'
      row(-1).font_style = :bold
      column(1).align = :right
    end

    pdf.move_down 15
  end

  def render_terms(pdf)
    if @contract.terms_and_conditions.present?
      pdf.text 'CONDITIONS GÉNÉRALES', size: 14, style: :bold
      pdf.move_down 10
      pdf.text @contract.terms_and_conditions, size: 9
      pdf.move_down 15
    else
      # Default terms
      pdf.text 'CONDITIONS GÉNÉRALES', size: 14, style: :bold
      pdf.move_down 10
      
      default_terms = [
        "1. Le présent contrat prend effet à la date de signature par les deux parties.",
        "2. L'acompte versé n'est pas remboursable en cas d'annulation par le locataire.",
        "3. Le locataire s'engage à respecter les règles d'utilisation de l'espace.",
        "4. Toute dégradation des lieux sera à la charge du locataire.",
        "5. Le loueur se réserve le droit d'annuler la réservation en cas de force majeure.",
        "6. Le solde doit être réglé au plus tard le jour de l'événement."
      ]
      
      default_terms.each do |term|
        pdf.text term, size: 9
        pdf.move_down 3
      end
      
      pdf.move_down 15
    end
  end

  def render_signatures(pdf)
    pdf.text 'SIGNATURES', size: 14, style: :bold
    pdf.move_down 10

    # Signature boxes
    pdf.bounding_box([0, pdf.cursor], width: 240, height: 100) do
      pdf.stroke_bounds
      pdf.move_down 5
      pdf.text '  Le Loueur:', size: 10, style: :bold
      pdf.move_down 10
      pdf.text "  #{@contract.company.name}", size: 9
      pdf.move_down 40
      pdf.text '  Date: ____________________', size: 9
    end

    pdf.bounding_box([280, pdf.cursor + 100], width: 240, height: 100) do
      pdf.stroke_bounds
      pdf.move_down 5
      pdf.text '  Le Locataire:', size: 10, style: :bold
      pdf.move_down 10
      pdf.text "  #{@contract.client.firstname} #{@contract.client.lastname}", size: 9
      pdf.move_down 40
      pdf.text '  Date: ____________________', size: 9
    end

    pdf.move_down 20
    pdf.text 'Mention manuscrite "Lu et approuvé":', size: 9, style: :italic
  end

  def render_footer(pdf)
    pdf.go_to_page(pdf.page_count)
    pdf.bounding_box([0, 30], width: pdf.bounds.width, height: 25) do
      pdf.stroke_horizontal_rule
      pdf.move_down 5
      pdf.text "Document généré le #{I18n.l(Time.current, format: :long)} - #{@contract.contract_number}", 
               size: 8, align: :center, color: '888888'
    end
  end

  def format_price(amount)
    number_to_currency(amount || 0, unit: @currency, format: '%n %u', separator: ',', delimiter: ' ')
  end
end
