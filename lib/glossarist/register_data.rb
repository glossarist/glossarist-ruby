# frozen_string_literal: true

module Glossarist
  class RegisterData < Lutaml::Model::Serializable
    attribute :key, :string, default: -> { "register" }
    attribute :shortname, :string
    attribute :name, :string
    attribute :description, :string
    attribute :schema_version, :string
    attribute :version, :string
    attribute :owner, :string
    attribute :languages, :string, collection: true
    attribute :subregisters, :hash, default: -> { {} }
    attribute :uri_prefix, :string
    attribute :concept_uri_template, :string
    attribute :homepage, :string
    attribute :repository, :string
    attribute :license, :string
    attribute :tags, :string, collection: true
    attribute :translations, :hash, default: -> {}
    # Dataset-register fields (concept-browser Deployments). These were
    # previously dropped during GCR packaging, causing downstream
    # consumers (e.g. concept-browser's lineage-series renderer) to lose
    # year/ref/urn/status needed for timeline sorting and identity.
    attribute :ref, :string
    attribute :ref_aliases, :string, collection: true
    attribute :year, :integer
    attribute :urn, :string
    attribute :urn_aliases, :string, collection: true
    attribute :status, :string
    attribute :supersedes, :string
    attribute :source_repo, :string

    key_value do
      map %i[id shortname], to: :shortname
      map "name", to: :name
      map "description", to: :description
      map "schema_version", to: :schema_version
      map "version", to: :version
      map "owner", to: :owner
      map "languages", to: :languages
      map "subregisters", to: :subregisters
      map "uri_prefix", to: :uri_prefix
      map "concept_uri_template", to: :concept_uri_template
      map "homepage", to: :homepage
      map "repository", to: :repository
      map "license", to: :license
      map "tags", to: :tags
      map "translations", to: :translations
      map "ref", to: :ref
      map "ref_aliases", to: :ref_aliases
      map "year", to: :year
      map "urn", to: :urn
      map "urn_aliases", to: :urn_aliases
      map "status", to: :status
      map "supersedes", to: :supersedes
      map "source_repo", to: :source_repo
    end

    def self.from_file(path)
      return nil unless File.exist?(path)

      from_yaml(File.read(path, encoding: "utf-8"))
    end
  end
end
