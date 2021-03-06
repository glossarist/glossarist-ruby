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
        super().merge({
          "type" => type.to_s,
          "international" => international,
        }).compact
      end
    end
  end
end
