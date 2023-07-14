module Glossarist
  class InvalidLanguageCodeError < Error
    attr_reader :code

    def initialize(code:)
      @code = code

      super()
    end

    def to_s
      "Invalid value for language_code: `#{code}`. It must be 3 characters long string."
    end
  end
end
