# frozen_string_literal: true

module Glossarist
  class ManagedConceptCollection
    include Enumerable

    attr_accessor :managed_concepts

    def initialize
      @managed_concepts = []
      @managed_concepts_ids = {}
    end

    def to_h
      {
        "managed_concepts" => managed_concepts.map(&:to_yaml_hash),
      }.compact
    end

    def each(&)
      @managed_concepts.each(&)
    end

    # Returns concept with given ID, if it is present in collection, or +nil+
    # otherwise.
    #
    # @param id [String]
    #    ManagedConcept ID
    # @return [ManagedConcept, nil]
    def fetch(id)
      @managed_concepts.find do |c|
        c.uuid == id || c.uuid == @managed_concepts_ids[id]
      end
    end
    alias :[] :fetch

    def by_id_and(id, version = nil)
      return fetch(id) if version.nil?

      @managed_concepts.find do |c|
        next false unless c.uuid == id || c.uuid == @managed_concepts_ids[id]

        c.version == version
      end
    end

    # If ManagedConcept with given ID is present in this collection, then
    # returns it. Otherwise, instantiates a new ManagedConcept, adds it to
    # the collection, and returns it.
    #
    # @param id [String]
    #    ManagedConcept ID
    # @return [ManagedConcept]
    def fetch_or_initialize(id)
      fetch(id) or store(Config.class_for(:managed_concept).of_yaml(data: { id: id }))
    end

    # Adds concept to the collection. If collection contains a concept with
    # the same ID already, that concept is replaced.
    #
    # @param managed_concept [ManagedConcept]
    #   ManagedConcept about to be added
    def store(managed_concept)
      @managed_concepts ||= []
      @managed_concepts << managed_concept
      if managed_concept.data.id
        @managed_concepts_ids[managed_concept.data.id] =
          managed_concept.uuid
      end

      managed_concept
    end
    alias :<< :store

    def load_from_files(path)
      store = GlossaryStore.new
      store.load(path)
      store.concepts.each { |mc| store(mc) }
      @localized_concepts_path = store.localized_concepts_dir_name || "localized_concept"
    end

    def save_to_files(path)
      concept_dir = File.join(path, "concept")
      lc_dir = File.join(path, @localized_concepts_path || "localized_concept")
      FileUtils.mkdir_p(concept_dir)
      FileUtils.mkdir_p(lc_dir)

      @managed_concepts.each do |mc|
        File.write(File.join(concept_dir, "#{mc.uuid}.yaml"), mc.to_yaml,
                   encoding: "utf-8")

        mc.localized_concepts.each do |lang, uuid|
          l10n = mc.localization(lang)
          next unless l10n

          File.write(File.join(lc_dir, "#{uuid}.yaml"), l10n.to_yaml,
                     encoding: "utf-8")
        end
      end
    end

    def save_grouped_concepts_to_files(path)
      FileUtils.mkdir_p(path)

      @managed_concepts.each do |mc|
        parts = [mc.to_yaml]
        mc.localized_concepts.each_key do |lang|
          l10n = mc.localization(lang)
          parts << l10n.to_yaml if l10n
        end
        File.write(File.join(path, "#{mc.uuid}.yaml"), parts.join("\n"),
                   encoding: "utf-8")
      end
    end
  end
end
