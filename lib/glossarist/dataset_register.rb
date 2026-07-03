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

    # Returns all ancestor section IDs for a given section, from immediate
    # parent up to the root. Implements the cascading membership semantics:
    # a concept in section "3.1.1" is also a member of "3.1" and "3".
    # (concept-model: gloss:hasChildSection / gloss:hasParentSection are
    # owl:TransitiveProperty.)
    def section_ancestor_ids(target_id)
      @section_parent_index ||= build_section_parent_index
      @section_parent_index[target_id] || []
    end

    # Returns all section IDs that a concept belongs to, including
    # transitive ancestor sections (cascading membership).
    #
    # Resolution order (concept-model convention):
    # 1. Explicit domains[] entries with ref_type: "section"
    # 2. Term-ID-prefix derivation fallback (longest registered prefix)
    #
    # @param concept [ManagedConcept, #data] the concept to resolve
    # @return [Array<String>] section IDs, child-first then ancestors
    def concept_section_ids(concept)
      explicit = explicit_section_ids(concept)
      ids = explicit.empty? ? derive_section_ids_from_id(concept) : explicit
      ids.flat_map { |id| [id] + section_ancestor_ids(id) }.uniq
    end

    # Returns true if the given section ID exists anywhere in the section
    # tree (root or descendant).
    def section_exists?(target_id)
      !section_by_id(target_id).nil?
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

    private

    # Build a flat child→[ancestor_ids] index by walking the section tree.
    # Ancestors are ordered immediate-parent-first (closest section first).
    # @example for sections [{id:"3", children:[{id:"3.1"}]}]:
    #   { "3.1" => ["3"] }
    def build_section_parent_index
      index = {}
      walk_section_tree(sections, []) do |section, ancestors|
        index[section.id] = ancestors.reverse unless ancestors.empty?
      end
      index
    end

    def walk_section_tree(nodes, ancestors, &block)
      Array(nodes).each do |section|
        yield section, ancestors
        child_ancestors = ancestors + [section.id]
        walk_section_tree(section.children, child_ancestors, &block)
      end
    end

    def explicit_section_ids(concept)
      domains = concept.is_a?(ManagedConcept) ? concept.data&.domains : nil
      Array(domains).select { |d| d.ref_type == "section" }
        .filter_map(&:concept_id)
    end

    # Term-ID-prefix derivation: when a concept has no explicit section
    # domains, derive section membership from its identifier using the
    # longest registered section prefix.
    # @example "103-01-01" with section "103" registered → ["103"]
    def derive_section_ids_from_id(concept)
      concept_id = concept.is_a?(ManagedConcept) ? concept.data&.id : nil
      return [] unless concept_id

      all_section_ids = collect_all_section_ids
      all_section_ids.select { |sid| concept_id.start_with?("#{sid}-", "#{sid}.") }
        .max_by(&:length)
        &.then { |sid| [sid] } || []
    end

    def collect_all_section_ids
      ids = []
      walk_section_tree(sections, []) { |section, _| ids << section.id }
      ids
    end
  end
end
