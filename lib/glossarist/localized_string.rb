# frozen_string_literal: true

module Glossarist
  # Semantic operations on localized string fields.
  #
  # Localized strings are stored as hashes keyed by ISO 639 language code:
  #   { "eng" => "Mixed reflection", "fra" => "Réflexion mixte" }
  #
  # This module provides typed access and fallback logic. It does not
  # introduce a wrapper class — the hash IS the localized string, matching
  # how Section#names, DatasetRegister#description, etc. already work.
  module LocalizedString
    # Fetch a localized value with language fallback.
    #
    # @param hash [Hash, nil] the localized string hash
    # @param lang [String, Symbol] the desired language code
    # @param fallback [String, nil] fallback language (default "eng")
    # @return [String, nil] the localized value, or nil if not found
    def self.fetch(hash, lang, fallback = "eng")
      return nil unless hash.is_a?(Hash)

      direct = hash[lang.to_s] || hash[lang.to_sym]
      return direct if direct

      fallback && fallback.to_s != lang.to_s ? hash[fallback.to_s] || hash[fallback.to_sym] : nil
    end

    # Check if a localized string hash is nil or empty.
    #
    # @param hash [Hash, nil]
    # @return [Boolean]
    def self.empty?(hash)
      hash.nil? || hash.empty?
    end

    # Check if a localized string hash has any entries.
    #
    # @param hash [Hash, nil]
    # @return [Boolean]
    def self.present?(hash)
      !empty?(hash)
    end
  end
end
