# frozen_string_literal: true

module Glossarist
  class Concept < Model
    attribute :termid, :string

    alias :id :termid
    alias :id= :termid=

    # attribute :superseded_concepts # TODO

    attribute :localizations, default: {}

    # def attributes
    def to_h
      {
        "termid" => termid,
        "term" => default_term,
        **localizations.transform_values(&:to_h),
      }
    end

    def default_localization
      localizations["eng"]
    end

    def default_term
      default_localization&.terms&.dig(0, "designation")
    end

    # def to_yaml
    #   to_serializable.to_yaml
    # end

    # def to_h
    #   attributes
    # end

    # def to_h
    #   h = super
    #   translations =
    #   h.merge(h.delete("localizations").transform_values(&:to_h))
    # end

    # def add_localization(localization)
    #   lang = localization.language_code
    #   localizations.store lang, localization
    # end

    # alias :add_l10n :add_localization

    # def localization(lang)
    #   localizations[lang]
    # end

    # alias :l10n :localization
  end
end
