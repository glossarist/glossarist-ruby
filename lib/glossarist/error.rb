require_relative "error/invalid_type_error"
require_relative "error/invalid_language_code_error"
require_relative "error/parse_error"

module Glossarist
  class Error < StandardError
  end
end
