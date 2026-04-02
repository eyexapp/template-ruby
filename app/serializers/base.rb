# frozen_string_literal: true

module Serializers
  module Base
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def attributes(*attrs)
        @attributes = attrs
      end

      def defined_attributes
        @attributes || []
      end

      def serialize(object, fields: nil)
        selected = fields || defined_attributes
        data = {}
        selected.each do |attr|
          data[attr] = if object.is_a?(Hash)
                         object[attr] || object[attr.to_s]
                       else
                         object.public_send(attr)
                       end
        end
        data
      end

      def collection(objects, fields: nil)
        objects.map { |obj| serialize(obj, fields: fields) }
      end
    end
  end
end

# Example usage:
#
# class UserSerializer
#   include Serializers::Base
#   attributes :id, :email, :name, :created_at
# end
#
# UserSerializer.serialize(user)
# UserSerializer.collection(users)
# UserSerializer.serialize(user, fields: [:id, :email])
