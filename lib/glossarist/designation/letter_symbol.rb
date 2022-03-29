# frozen_string_literal: true

module Glossarist
  module Designation
    class LetterSymbol < Symbol
      attr_accessor :text
      attr_accessor :language
      attr_accessor :script

      def to_h
        super.merge(
          "text" => text,
          "language" => language,
          "script" => script,
        )
      end
    end
  end
end
