# frozen_string_literal: true

module Glossarist
  class ConceptReference < Lutaml::Model::Serializable
    attribute :term, :string
    attribute :concept_id, :string
    attribute :source, :string
    attribute :ref_type, :string

    yaml do
      map :term, to: :term
      map :concept_id, to: :concept_id
      map :source, to: :source
      map :ref_type, to: :ref_type
    end

    def local?
      %w[local designation].include?(ref_type) ||
        (ref_type.nil? && (source.nil? || source.empty?))
    end

    def external?
      !local?
    end

    def to_urn
      return nil unless external?
      return nil unless source && concept_id

      case source
      when /\Aurn:iec/ then "#{source}-#{concept_id}"
      when /\Aurn:iso/ then "#{source}:term:#{concept_id}"
      else "#{source}/#{concept_id}"
      end
    end

    def to_gcr_hash
      h = { "term" => term }
      h["concept_id"] = concept_id if concept_id
      h["source"] = source if source
      h["ref_type"] = ref_type if ref_type
      h.compact
    end
  end
end
