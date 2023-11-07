# frozen_string_literal: true

module Glossarist
  module Utilities
    module CommonFunctions
      # Hash#transform_keys is not available in Ruby 2.4
      # so we have to do this ourselves :(
      # symbolize hash keys
      def symbolize_keys(hash)
        result = {}
        hash.each_pair do |key, value|
          result[key.to_sym] = if value.is_a?(Hash)
                                 symbolize_keys(value)
                               else
                                 value
                               end
        end
        result
      end

      # Hash#transform_keys is not available in Ruby 2.4
      # so we have to do this ourselves :(
      # symbolize hash keys
      def stringify_keys(hash)
        result = {}
        hash.each_pair do |key, value|
          result[key.to_s] = if value.is_a?(Hash)
                               stringify_keys(value)
                             else
                               value
                             end
        end
        result
      end

      # Hash#slice is not available in Ruby 2.4
      # so we have to do this ourselves :(
      # slice hash keys
      def slice_keys(hash, keys)
        result = {}
        keys.each do |key|
          result[key] = hash[key] if hash.key?(key)
        end
        result
      end

      def convert_keys_to_snake_case(hash)
        result = {}
        hash.each_pair do |key, value|
          result[snake_case(key)] = if value.is_a?(Hash)
                                      convert_keys_to_snake_case(value)
                                    else
                                      value
                                    end
        end
        result
      end

      def snake_case(str)
        str.gsub(/([A-Z])/) { "_#{$1.downcase}" }
      end
    end
  end
end
