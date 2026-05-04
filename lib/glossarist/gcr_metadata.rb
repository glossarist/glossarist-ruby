# frozen_string_literal: true

module Glossarist
  class GcrMetadata < Lutaml::Model::Serializable
    attribute :shortname, :string
    attribute :version, :string
    attribute :title, :string
    attribute :description, :string
    attribute :owner, :string
    attribute :tags, :string, collection: true
    attribute :concept_count, :integer
    attribute :languages, :string, collection: true
    attribute :created_at, :string
    attribute :glossarist_version, :string
    attribute :schema_version, :string, default: -> { "1.0.0" }
    attribute :statistics, GcrStatistics
    attribute :homepage, :string
    attribute :repository, :string
    attribute :license, :string
    attribute :uri_prefix, :string
    attribute :concept_uri_template, :string
    attribute :external_references, :hash, collection: true

    key_value do
      map :shortname, to: :shortname
      map :version, to: :version
      map :title, to: :title
      map :description, to: :description
      map :owner, to: :owner
      map :tags, to: :tags
      map :concept_count, to: :concept_count
      map :languages, to: :languages
      map :created_at, to: :created_at
      map :glossarist_version, to: :glossarist_version
      map :schema_version, to: :schema_version
      map :statistics, to: :statistics
      map :homepage, to: :homepage
      map :repository, to: :repository
      map :license, to: :license
      map :uri_prefix, to: :uri_prefix
      map :concept_uri_template, to: :concept_uri_template
      map :external_references, to: :external_references
    end

    def self.from_concepts(concepts, register_data: nil, options: {})
      stats = GcrStatistics.from_concepts(concepts)
      new(
        shortname: options[:shortname] || register_data&.dig("shortname") || register_data&.dig("id"),
        version: options[:version] || register_data&.dig("version"),
        title: options[:title] || register_data&.dig("name"),
        description: options[:description] || register_data&.dig("description"),
        owner: options[:owner],
        tags: options[:tags] || [],
        concept_count: concepts.length,
        languages: stats.languages,
        created_at: Time.now.utc.iso8601,
        glossarist_version: Glossarist::VERSION,
        schema_version: register_data&.dig("schema_version") || SchemaMigration::CURRENT_SCHEMA_VERSION,
        statistics: stats,
        uri_prefix: options[:uri_prefix],
        concept_uri_template: options[:concept_uri_template],
        external_references: derive_external_references(concepts),
      )
    end

    def self.derive_external_references(concepts)
      sources = Set.new
      concepts.each do |concept|
        concept.localizations.each do |l10n|
          l10n.data.references&.each do |ref|
            src = ref.source
            sources.add(src) if src && !src.empty?
          end
        end
      end
      sources.map { |uri| { "uri" => uri } }
    end

    def [](key)
      to_yaml_hash[key]
    end

    def dig(*keys)
      to_yaml_hash.dig(*keys)
    end
  end
end
