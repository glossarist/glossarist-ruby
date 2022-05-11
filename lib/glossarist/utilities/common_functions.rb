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
          result[key.to_sym] = value
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
    end
  end
end
