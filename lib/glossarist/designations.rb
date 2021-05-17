# frozen_string_literal: true

module Glossarist
  class Designation < Model
    attribute :normative_status, Types::Symbol
  end

  class ExpressionDesignation < Designation
    attribute :designation, Types::String
    attribute :gender, Types::String
    attribute :plurality, Types::String
    attribute :part_of_speech, Types::String
  end
end
