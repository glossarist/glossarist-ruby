# frozen_string_literal: true

require_relative "base"

module Glossarist
  module Designation
    class Symbol < Base
      attr_accessor :international

      def to_h
        {
          "type" => "symbol",
          "normative_status" => normative_status,
          "geographical_area" => geographical_area,
          "designation" => designation,
          "international" => international,
        }.compact
      end
    end
  end
end
