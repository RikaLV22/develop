module JsonWebToken
    SECRET_KEY = Rails.application.secret_key_base

    def encode(payload)
        jwt.encode(payload, SECRET_KEY)
    end

    def decode(token)
        jwt.decode(token,SECRET_KEY)[0]
    end
end