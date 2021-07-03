# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module Glossarist
  module Designations
    class Base < Model
      # @note This is not entirely aligned with agreed schema and may be
      #   changed.
      attr_accessor :designation

      attr_accessor :normative_status
      attr_accessor :geographical_area
    end

    class Expression < Base
      attr_accessor :gender
      attr_accessor :part_of_speech
      attr_accessor :plurality
      attr_accessor :prefix
      attr_accessor :usage_info
    end

    class Symbol < Base
      attr_accessor :international
    end
  end
end
