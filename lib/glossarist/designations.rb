# frozen_string_literal: true

module Glossarist
  class Designation < Model
    attribute :normative_status, :string
  end

  class ExpressionDesignation < Designation
    attribute :designation, :string
    attribute :gender, :string
    attribute :plurality, :string
    attribute :part_of_speech, :string
  end
end
