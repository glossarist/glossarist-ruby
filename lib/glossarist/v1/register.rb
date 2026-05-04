# frozen_string_literal: true

module Glossarist
  module V1
    class Register < Lutaml::Model::Serializable
      attribute :data, :hash, default: -> { {} }

      key_value do
        map nil, to: :data, with: { from: :data_from, to: :data_to }
      end

      def self.from_file(path)
        return nil unless File.exist?(path)

        register = from_yaml(File.read(path))
        return nil unless register.data.is_a?(Hash) && !register.data.empty?

        register
      rescue Psych::SyntaxError, Lutaml::Model::InvalidFormatError
        nil
      end

      def [](key)
        data[key]
      end

      def dig(*keys)
        data.dig(*keys)
      end

      def schema_version
        data["schema_version"]&.to_s
      end

      def to_h
        data
      end

      def data_from(model, value)
        model.data = value
      end

      def data_to(model, doc)
        model.data.each do |key, value|
          doc[key] = value
        end
      end
    end
  end
end
