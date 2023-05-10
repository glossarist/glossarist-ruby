# frozen_string_literal: true

require_relative "expression"
require_relative "../utilities"

module Glossarist
  module Designation
    class Abbreviation < Expression
      include Glossarist::Utilities::Enum

      register_enum :type, Glossarist::GlossaryDefinition::ABBREVIATION_TYPES

      attr_accessor :international

      def to_h
        type_hash = {
          "type" => "abbreviation",
          "international" => international,
        }

        type_hash[type.to_s] = true if type

        super().merge(type_hash).compact
      end
    end
  end
end
