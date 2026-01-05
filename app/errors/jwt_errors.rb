# app/errors/jwt_errors.rb
module JwtErrors
  class Expired < StandardError; end
  class Invalid < StandardError; end
end
