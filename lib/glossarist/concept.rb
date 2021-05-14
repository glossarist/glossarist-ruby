# frozen_string_literal: true

module Glossarist
  class Concept < Model
    attribute :termid, :string

    alias :id :termid

    attr_reader :localizations

    # attribute :superseded_concepts # TODO

    # attribute :localizations, default: {}

    def initialize(*args)
      super
      @localizations = Hash.new
    end

    def attributes
      {
        "termid" => termid,
        "term" => localizations["eng"].terms&.dig(0, "designation"),
        **localizations.to_h
      }
      # require
      # {

      # super.merge
      # }
    end

    # def to_h
    #   attributes
    # end

    # def to_h
    #   h = super
    #   translations =
    #   h.merge(h.delete("localizations").transform_values(&:to_h))
    # end

    def add_localization(localization)
      lang = localization.language_code
      localizations.store lang, localization
    end

    alias :add_l10n :add_localization

    def localization(lang)
      localizations[lang]
    end

    alias :l10n :localization
  end
end
