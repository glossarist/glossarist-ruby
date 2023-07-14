module Glossarist
  class ParseError < Error
    attr_accessor :line, :filename

    def initialize(filename:, line: nil)
      @filename = filename
      @line = line

      super()
    end

    def to_s
      "Unable to parse file: #{filename}, error on line: #{line}"
    end
  end
end
