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
    end

    def [](key)
      case key
      when "shortname", "id" then shortname
      when "name" then name
      when "description" then description
      when "schema_version" then schema_version
      when "version" then version
      when "owner" then owner
      when "languages" then languages
      when "subregisters" then subregisters
      when "uri_prefix" then uri_prefix
      when "concept_uri_template" then concept_uri_template
      when "homepage" then homepage
      when "repository" then repository
      when "license" then license
      when "tags" then tags
      end
    end

    def dig(*keys)
      return nil if keys.empty?

      first = self[keys.first]
      keys.length == 1 ? first : nil
    end

    def to_h
      h = {}
      h["shortname"] = shortname if shortname
      h["name"] = name if name
      h["description"] = description if description
      h["schema_version"] = schema_version if schema_version
      h["version"] = version if version
      h["owner"] = owner if owner
      h["languages"] = languages if languages && !languages.empty?
      h["subregisters"] = subregisters if subregisters && !subregisters.empty?
      h["uri_prefix"] = uri_prefix if uri_prefix
      h["concept_uri_template"] = concept_uri_template if concept_uri_template
      h["homepage"] = homepage if homepage
      h["repository"] = repository if repository
      h["license"] = license if license
      h["tags"] = tags if tags && !tags.empty?
      h
    end

    def self.from_file(path)
      return nil unless File.exist?(path)

      from_yaml(File.read(path, encoding: "utf-8"))
    end
  end
end
