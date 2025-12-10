# app/services/facture_service.rb
require 'receipts'

class FactureService
  def self.generate(consultation)
    # Set the amount to a default value if not provided
    amount = consultation.doctor.amount || 70.0 

    receipt = Receipts::Receipt.new(
      details: [
        ["Receipt Number", consultation.id],
        ["Date Paid", consultation.updated_at.strftime('%d/%m/%Y')],
        ["Payment Method", "Online Payment"]
      ],
      company: {
        name: "Your Platform Name",
        address: "123 Platform Address\nCity, Country, ZIP",
        email: "support@yourplatform.com",
        logo: Rails.root.join("app/assets/images/logo_with_beta.png")
      },
      recipient: [
        consultation.patient.firstname,
        "Address if available",
        "City, State, ZIP",
        consultation.patient.location,

        consultation.patient.email
      ],
      line_items: [
        ["<b>Item</b>", "<b>Unit Cost</b>", "<b>Consultation</b>", "<b>Amount</b>"],
        ["Consultation with Dr. #{consultation.doctor.firstname} #{consultation.doctor.lastname}", "#{amount} TND", "1", "#{amount} TND"],
        [nil, nil, "Subtotal", "#{amount} TND"],
        [nil, nil, "DermaPro Fee (10%)", "#{(amount * 0.10).round(2)} TND"],
        [nil, nil, "Total", "#{(amount * 0.90).round(2)} TND"], # Total after the platform fee
        [nil, nil, "<b>Amount Paid</b>", "#{amount} TND"]
      ],
      footer: "Thanks for your business. Please contact us if you have any questions."
    )

    # Save the PDF to a file or return the raw data
    file_path = Rails.root.join("tmp", "facture_#{consultation.id}.pdf")
    receipt.render_file(file_path)
    file_path
  end
end
