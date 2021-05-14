# frozen_string_literal: true

module Glossarist
  class Concept < Model
    attribute :termid, :string

    alias :id :termid
    alias :id= :termid=

    # attr_reader :localizations

    # attribute :superseded_concepts # TODO

    attribute :localizations, default: {}

    # def initialize(*)
    #   # @localizations = Hash.new
    # # def initialize(*args, **kwargs)
    #   require 'pry'
    #   # binding.pry
    #   super
    #   # binding.pry
    # end

    def to_serializable
      # require 'pry'
      # binding.pry

      # require
      # {

      # super.merge
      # }
    end

    def to_yaml
      h = {
        "termid" => termid,
        "term" => localizations["eng"]&.terms&.dig(0, "designation"),
        **localizations.to_h,
      }

      h.to_yaml
    end

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
