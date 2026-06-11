# frozen_string_literal: true

module Glossarist
  module Errors
    autoload :Base, "glossarist/errors/base"
    autoload :ParseError, "glossarist/errors/parse_error"
    autoload :LoadError, "glossarist/errors/load_error"
    autoload :InvalidTypeError, "glossarist/errors/invalid_type_error"
    autoload :InvalidLanguageCodeError, "glossarist/errors/invalid_language_code_error"
    autoload :CacheVersionMismatchError, "glossarist/errors/cache_version_mismatch_error"
  end
end
