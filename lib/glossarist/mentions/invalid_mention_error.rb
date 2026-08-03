# frozen_string_literal: true

module Glossarist
  module Mentions
    class InvalidMentionError < StandardError
      attr_reader :raw, :reason, :position

      def initialize(raw:, reason:, position: 0)
        @raw = raw
        @reason = reason
        @position = position
        super("Invalid mention at position #{position}: #{reason}")
      end
    end
  end
end
