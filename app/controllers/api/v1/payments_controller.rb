class Api::V1::PaymentsController < ApplicationController
  def create_payment
    consultation = Consultation.find(params[:consultation_id])
    data = {
      receiverWalletId: "672de5dabe34904520699652",
      token: "TND",
      amount: consultation.doctor.amount || 1000,
      type: "immediate",
      acceptedPaymentMethods: [
        "wallet",
        "bank_card",
        "e-DINAR"
      ],
      successUrl: "http://localhost:4200/patient/appointment-request/?payment_id=#{consultation.id}",
      failUrl: "http://localhost:4200/patient/appointment-request/fail",
      description: "Payment for consultation ##{consultation.id}"
    }

    # Set up the URI and HTTP request
    uri = URI.parse("https://api.preprod.konnect.network/api/v2/payments/init-payment")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    # Create the POST request
    request = Net::HTTP::Post.new(uri.path) # Corrected class here
    request["x-api-key"] = ENV["X_API_KEY"]
    request["Content-Type"] = "application/json"
    request.body = data.to_json

    # Send the request and parse the response
    response = http.request(request)
    payment_data = JSON.parse(response.body)

    if payment_data.key?("payUrl") && payment_data.key?("paymentRef")
      payment_url = payment_data["payUrl"]
      payment_id = payment_data["paymentRef"]

      # Create the Payment record
      consultation.create_payment(
        payment_id: payment_id,
        amount: data[:amount],
        status: 0
      )
      # Payment.create!(
      #   consultation: consultation,
      #   payment_id: payment_id,
      #   amount: data[:amount],
      #   status: 0 # Initial status (e.g., pending)
      # )

      # Render the URL as response
      render json: {url: payment_url}
    else
      render json: {error: "Failed to generate payment URL"}, status: :unprocessable_entity
    end
  end

  def generate_facture
    consultation = Consultation.find(params[:id])

    # Call the FactureService to generate the PDF
    pdf_path = FactureService.generate(consultation)

    # Send the PDF as a response
    send_file pdf_path, type: "application/pdf", disposition: "inline", filename: "facture_#{consultation.id}.pdf"
  end
end
