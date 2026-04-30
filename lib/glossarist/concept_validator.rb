# frozen_string_literal: true

require "yaml"

module Glossarist
  class ConceptValidator
    LANG_CODES = %w[eng ara deu fra spa ita jpn kor pol por srp swe zho rus fin dan nld msa nob nno].freeze
    VALID_ENTRY_STATUSES = %w[valid superseded withdrawn draft].freeze

    attr_reader :path, :errors, :warnings

    def initialize(path)
      @path = path
      @errors = []
      @warnings = []
    end

    def validate_all
      seen_termids = {}

      concept_files.each do |file|
        validate_concept_file(file, seen_termids)
      end

      ValidationResult.new(errors: @errors, warnings: @warnings)
    end

    private

    def concept_files
      concepts_dir = File.directory?(File.join(@path, "concepts")) \
        ? File.join(@path, "concepts") \
        : @path
      Dir.glob(File.join(concepts_dir, "*.yaml"))
    end

    def validate_concept_file(file, seen_termids)
      hash = YAML.safe_load_file(file, permitted_classes: [Date, Time])
    rescue Psych::SyntaxError => e
      @errors << "#{File.basename(file)}: YAML parse error at line #{e.line}: #{e.message}"
      return
    rescue => e
      @errors << "#{File.basename(file)}: #{e.message}"
      return
    else
      validate_termid(hash, file, seen_termids)
      validate_language_blocks(hash, file)
      validate_definitions(hash, file)
      validate_sources(hash, file)
      validate_entry_statuses(hash, file)
      validate_terms_designations(hash, file)
      validate_no_revisions(hash, file)
    end

    def validate_termid(hash, file, seen_termids)
      fname = File.basename(file)
      unless hash.key?("termid")
        @errors << "#{fname}: missing termid"
        return
      end

      termid = hash["termid"]
      unless termid.is_a?(String)
        @errors << "#{fname}: termid must be a string, got #{termid.class}"
      end

      if seen_termids[termid]
        @errors << "#{fname}: duplicate termid '#{termid}' (first seen in #{seen_termids[termid]})"
      else
        seen_termids[termid] = fname
      end
    end

    def validate_language_blocks(hash, file)
      fname = File.basename(file)
      langs = LANG_CODES.select { |l| hash[l].is_a?(Hash) }
      if langs.empty?
        @errors << "#{fname}: no language blocks found"
        return
      end

      langs.each do |lang|
        terms = hash[lang]["terms"]
        unless terms.is_a?(Array) && terms.any?
          @errors << "#{fname}/#{lang}: must have at least 1 term"
        end
      end
    end

    def validate_definitions(hash, file)
      fname = File.basename(file)
      LANG_CODES.each do |lang|
        next unless hash[lang].is_a?(Hash)
        next unless hash[lang].key?("definition")

        defn = hash[lang]["definition"]
        if defn.is_a?(String)
          @errors << "#{fname}/#{lang}: definition is bare string (expected array)"
        elsif !defn.is_a?(Array)
          @errors << "#{fname}/#{lang}: definition must be an array"
        elsif defn.any? { |d| !d.is_a?(Hash) || !d.key?("content") }
          @errors << "#{fname}/#{lang}: definition items must have 'content' key"
        end
      end
    end

    def validate_sources(hash, file)
      fname = File.basename(file)
      LANG_CODES.each do |lang|
        next unless hash[lang].is_a?(Hash)

        if hash[lang].key?("authoritative_source")
          @errors << "#{fname}/#{lang}: has 'authoritative_source' (should be 'sources' array after migration)"
        end

        sources = hash[lang]["sources"]
        next unless sources

        unless sources.is_a?(Array)
          @errors << "#{fname}/#{lang}: sources must be an array"
        end
      end
    end

    def validate_entry_statuses(hash, file)
      fname = File.basename(file)
      LANG_CODES.each do |lang|
        next unless hash[lang].is_a?(Hash)
        next unless hash[lang].key?("entry_status")

        status = hash[lang]["entry_status"]
        unless VALID_ENTRY_STATUSES.include?(status)
          @errors << "#{fname}/#{lang}: invalid entry_status '#{status}' (expected one of: #{VALID_ENTRY_STATUSES.join(', ')})"
        end
      end
    end

    def validate_terms_designations(hash, file)
      fname = File.basename(file)
      LANG_CODES.each do |lang|
        next unless hash[lang].is_a?(Hash)
        next unless hash[lang]["terms"].is_a?(Array)

        hash[lang]["terms"].each_with_index do |term, idx|
          if term.is_a?(Hash) && term["abbrev"] == true
            @errors << "#{fname}/#{lang}/terms[#{idx}]: has 'abbrev: true' (should be 'type: abbreviation' after migration)"
          end
        end
      end
    end

    def validate_no_revisions(hash, file)
      fname = File.basename(file)
      if hash.key?("_revisions")
        @warnings << "#{fname}: has '_revisions' (stripped during migration)"
      end

      LANG_CODES.each do |lang|
        next unless hash[lang].is_a?(Hash)
        if hash[lang].key?("_revisions")
          @warnings << "#{fname}/#{lang}: has '_revisions' (stripped during migration)"
        end
      end
    end
  end
end
