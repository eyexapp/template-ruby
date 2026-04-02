# frozen_string_literal: true

module Services
  class Base
    Result = Struct.new(:success, :data, :error) do
      def success?
        success
      end

      def failure?
        !success
      end
    end

    def self.call(...)
      new(...).call
    end

    def call
      raise NotImplementedError, "#{self.class}#call must be implemented"
    end

    private

    def success(data = nil)
      Result.new(success: true, data: data, error: nil)
    end

    def failure(error)
      Result.new(success: false, data: nil, error: error)
    end
  end
end

# Example usage:
#
# class CreateUser < Services::Base
#   def initialize(params:)
#     @params = params
#   end
#
#   def call
#     user = User.create(@params)
#     success(user)
#   rescue Sequel::ValidationFailed => e
#     failure(e.message)
#   end
# end
#
# result = CreateUser.call(params: { email: "test@example.com" })
# if result.success?
#   json_response(result.data)
# else
#   halt_json(422, result.error)
# end
