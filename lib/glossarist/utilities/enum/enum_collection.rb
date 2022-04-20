# frozen_string_literal: true

module Glossarist
  module Utilities
    module Enum
      class EnumCollection
        include Enumerable

        Enumerator = Struct.new(:registered_values, :options, keyword_init: true)

        def initialize
          @collection = {}
        end

        def add(name, values, options = {})
          @collection[name] = { registered_values: values, options: options }
        end

        def each(&block)
          if block_given?
            @collection.each do |object|
              block.call(object)
            end
          else
            enum_for(:each)
          end
        end

        def registered_enums
          @collection&.keys || []
        end

        def valid_types(name)
          @collection[name][:registered_values]
        end

        def type_options(name)
          @collection[name][:options]
        end

        def [](name)
          @collection[name]
        end
      end
    end
  end
end
