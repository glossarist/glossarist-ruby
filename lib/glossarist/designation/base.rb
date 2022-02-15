# frozen_string_literal: true

module Glossarist
  module Designation
    class Base < Model
      # @note This is not entirely aligned with agreed schema and may be
      #   changed.
      attr_accessor :designation

      attr_accessor :normative_status
      attr_accessor :geographical_area

      def self.from_h(hash)
        type = hash["type"]

        if type.nil? || /\w/ !~ type
          raise ArgumentError, "designation type is missing"
        end

        designation_subclass = SERIALIZED_TYPES[type]

        if self == Base
          # called on Base class, delegate it to proper subclass
          SERIALIZED_TYPES[type].from_h(hash)
        else
          # called on subclass, instantiate object
          unless SERIALIZED_TYPES[self] == type
            raise ArgumentError, "unexpected designation type: #{type}"
          end
          super(hash.reject { |k, _| k == "type" })
        end
      end
    end
  end
end