# frozen_string_literal: true

module Glossarist
  class GcrMetadata
    attr_accessor :title, :description, :owner, :tags,
                  :concept_count, :languages,
                  :created_at, :glossarist_version, :schema_version,
                  :statistics, :homepage, :repository, :license

    def initialize(attrs = {})
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
    end

    def self.from_concepts(concepts, register_data: nil, options: {})
      stats = GcrStatistics.from_concepts(concepts)
      new(
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
      )
    end

    def to_h
      h = {
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
      h.compact
    end
  end
end
