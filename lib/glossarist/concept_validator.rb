# frozen_string_literal: true

module Glossarist
  class ConceptValidator
    LANG_CODES = Glossarist::LANG_CODES
    VALID_ENTRY_STATUSES = %w[valid superseded withdrawn draft].freeze

    attr_reader :path, :errors, :warnings

    def initialize(path)
      @path = path
      @errors = []
      @warnings = []
    end

    def validate_all
      seen_ids = {}
      file_idx = 0

      ConceptCollector.each_concept(@path) do |concept|
        fname = concept_file_name(concept, file_idx)
        validate_concept(concept, fname, seen_ids)
        file_idx += 1
      end

      if file_idx.zero?
        yaml_files = find_yaml_files
        if yaml_files.any?
          @errors << "YAML files found but no parseable concepts"
        end
      end

      ValidationResult.new(errors: @errors, warnings: @warnings)
    end

    private

    def find_yaml_files
      concepts_dir = if File.directory?(File.join(@path, "concepts"))
                       File.join(@path, "concepts")
                     else
                       @path
                     end
      Dir.glob(File.join(concepts_dir, "*.yaml"))
    end

    def concept_file_name(concept, idx)
      id = concept.data&.id
      id ? "concept-#{id}.yaml" : "concept-#{idx}.yaml"
    end

    def validate_concept(concept, fname, seen_ids)
      validate_id(concept, fname, seen_ids)
      validate_localizations(concept, fname)
      validate_entry_statuses(concept, fname)
    end

    def validate_id(concept, fname, seen_ids)
      id = concept.data&.id
      unless id
        @errors << "#{fname}: missing concept id"
        return
      end

      id_str = id.to_s
      if seen_ids[id_str]
        @errors << "#{fname}: duplicate id '#{id_str}' (first seen in #{seen_ids[id_str]})"
      else
        seen_ids[id_str] = fname
      end
    end

    def validate_localizations(concept, fname)
      l10ns = concept.localizations&.values || []
      if l10ns.empty?
        @errors << "#{fname}: no localizations found"
        return
      end

      l10ns.each do |l10n|
        lang = l10n.language_code || "unknown"
        terms = l10n.data&.terms
        unless terms.is_a?(Array) && terms.any?
          @errors << "#{fname}/#{lang}: must have at least 1 term"
        end
      end
    end

    def validate_entry_statuses(concept, fname)
      (concept.localizations&.values || []).each do |l10n|
        lang = l10n.language_code || "unknown"
        status = l10n.data&.entry_status
        next unless status

        unless VALID_ENTRY_STATUSES.include?(status)
          @errors << "#{fname}/#{lang}: invalid entry_status '#{status}' (expected one of: #{VALID_ENTRY_STATUSES.join(', ')})"
        end
      end
    end
  end
end
