# frozen_string_literal: true

module Glossarist
  class GcrMetadata
    attr_accessor :shortname, :version, :title, :description, :owner, :tags,
                  :concept_count, :languages,
                  :created_at, :glossarist_version, :schema_version,
                  :statistics, :homepage, :repository, :license,
                  :uri_prefix, :external_references

    def initialize(attrs = {})
      @shortname = attrs[:shortname]
      @version = attrs[:version]
      @title = attrs[:title]
      @description = attrs[:description]
      @owner = attrs[:owner]
      @tags = attrs[:tags] || []
      @concept_count = attrs[:concept_count] || 0
      @languages = attrs[:languages] || []
      @created_at = attrs[:created_at]
      @glossarist_version = attrs[:glossarist_version]
      @schema_version = attrs[:schema_version] || "1.0.0"
      @statistics = attrs[:statistics]
      @homepage = attrs[:homepage]
      @repository = attrs[:repository]
      @license = attrs[:license]
      @uri_prefix = attrs[:uri_prefix]
      @external_references = attrs[:external_references] || []
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
        external_references: derive_external_references(concepts),
      )
    end

    def self.derive_external_references(concepts)
      sources = Set.new
      concepts.each do |concept|
        Array(concept["references"]).each do |ref|
          src = ref.is_a?(Hash) ? ref["source"] : nil
          sources.add(src) if src && !src.empty?
        end
      end
      sources.map { |uri| { "uri" => uri } }
    end

    def to_h
      h = {
        "shortname" => shortname,
        "version" => version,
        "title" => title,
        "description" => description,
        "owner" => owner,
        "tags" => tags,
        "concept_count" => concept_count,
        "languages" => languages,
        "created_at" => created_at,
        "glossarist_version" => glossarist_version,
        "schema_version" => schema_version,
        "statistics" => statistics&.to_h,
      }
      h["homepage"] = homepage if homepage
      h["repository"] = repository if repository
      h["license"] = license if license
      h["uri_prefix"] = uri_prefix if uri_prefix
      h["external_references"] = external_references if external_references&.any?
      h.compact
    end
  end
end
