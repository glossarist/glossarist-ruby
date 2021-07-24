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
  end
end
