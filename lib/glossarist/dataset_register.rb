# frozen_string_literal: true

module Glossarist
  class DatasetRegister < Lutaml::Model::Serializable
    attribute :schema_type, :string, default: -> { "glossarist" }
    attribute :schema_version, :string, default: -> { "3" }
    attribute :id, :string
    attribute :ref, :string
    attribute :year, :integer
    attribute :urn, :string
    attribute :urn_aliases, :string, collection: true
    attribute :ref_aliases, :string, collection: true
    attribute :status, :string
    attribute :supersedes, :string
    attribute :owner, :string
    attribute :source_repo, :string
    attribute :tags, :string, collection: true
    attribute :languages, :string, collection: true
    attribute :language_order, :string, collection: true
    attribute :ordering, :string
    attribute :sections, Section, collection: true
    attribute :description, :hash
    attribute :about, :hash
    attribute :logo, :string

    key_value do
      map "schema_type", to: :schema_type
      map "schema_version", to: :schema_version
      map "id", to: :id
      map "ref", to: :ref
      map "year", to: :year
      map "urn", to: :urn
      map "urnAliases", to: :urn_aliases
      map "refAliases", to: :ref_aliases
      map "status", to: :status
      map "supersedes", to: :supersedes
      map "owner", to: :owner
      map "sourceRepo", to: :source_repo
      map "tags", to: :tags
      map "languages", to: :languages
      map "languageOrder", to: :language_order
      map "ordering", to: :ordering
      map "sections", to: :sections
      map "description", to: :description
      map "about", to: :about
      map "logo", to: :logo
    end

    def section_by_id(target_id)
      sections&.each do |section|
        return section if section.id == target_id

        found = section.descendant_by_id(target_id)
        return found if found
      end
      nil
    end

    def self.from_file(path)
      return nil unless File.exist?(path)

      from_yaml(File.read(path, encoding: "utf-8"))
    end

    def self.from_directory(dir)
      register_path = File.join(dir, "register.yaml")
      return nil unless File.exist?(register_path)

      from_file(register_path)
    end
  end
end
