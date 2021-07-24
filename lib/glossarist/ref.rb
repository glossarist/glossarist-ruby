# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module Glossarist
  class Ref < Model
    # Unstructured (plain text) reference.
    # @return [String]
    attr_accessor :text

    # Source in structured reference.
    # @return [String]
    attr_accessor :source

    # Document ID in structured reference.
    # @return [String]
    attr_accessor :id

    # Document version in structured reference.
    # @return [String]
    attr_accessor :version

    # @return [String]
    # Referred clause of the document.
    attr_accessor :clause

    # Link to document.
    # @return [String]
    attr_accessor :link

    # @return [String]
    # @todo Pending documentation.
    attr_accessor :status

    # @return [String]
    # @todo Pending documentation.
    attr_accessor :modification

    # Original ref text before parsing.
    # @return [String]
    # @note This attribute is likely to be removed or reworked in future.
    #   It is arguably not relevant to Glossarist itself.
    attr_accessor :original

    # Whether it is a plain text ref.
    # @return [Boolean]
    def plain?
      (source && id && version).nil?
    end

    # Whether it is a structured ref.
    # @return [Boolean]
    def structured?
      !plain?
    end

    def to_h
      {
        "ref" => ref_to_h,
        "clause" => clause,
        "link" => link,
        "relationship" => relationship_to_h,
        "original" => original,
      }.compact
    end

    def self.from_h(hash)
      hash = hash.dup

      ref_val = hash.delete("ref")
      rel_val = hash.delete("relationship")
      hash.merge!(Hash === ref_val ? ref_val : {"text" => ref_val})
      hash["status"] = rel_val&.fetch("type")
      hash["modification"] = rel_val&.fetch("modification")
      hash.compact!

      super(hash)
    end

    private

    def ref_to_h
      if structured?
        { "source" => source, "id" => id, "version" => version }.compact
      else
        text
      end
    end

    def relationship_to_h
      status && { "type" => status, "modification" => modification }.compact
    end
  end
end
