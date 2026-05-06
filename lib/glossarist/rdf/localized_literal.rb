# frozen_string_literal: true

module Glossarist
  module Rdf
    class LocalizedLiteral < Lutaml::Model::Serializable
      include Lutaml::Rdf::LanguageTagged

      attribute :value, :string
      attribute :language_code, :string

      key_value do
        map :value, to: :value
        map :language_code, to: :language_code
      end

      def language_tag
        language_code
      end

      def to_s
        value.to_s
      end
    end
  end
end
