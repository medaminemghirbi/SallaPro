class JsonWebToken
  SECRET_KEY = ENV['JWT_SECRET_KEY'] || Rails.application.secret_key_base.to_s

  ALGORITHM = "HS256"

  # Encode token
  def self.encode(payload, exp = 24.hours.from_now)
    payload = payload.dup
    payload[:exp] = exp.to_i

    JWT.encode(payload, SECRET_KEY, ALGORITHM)
  end

  # Decode token
  def self.decode(token)
    decoded = JWT.decode(
      token,
      SECRET_KEY,
      true,
      { algorithm: ALGORITHM }
    )[0]

    HashWithIndifferentAccess.new(decoded)

  rescue JWT::ExpiredSignature
    raise JwtExpiredError, "Token has expired"

  rescue JWT::DecodeError
    raise JwtInvalidError, "Invalid token"
  end
end
