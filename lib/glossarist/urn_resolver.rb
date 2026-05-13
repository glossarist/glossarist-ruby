# frozen_string_literal: true

module Glossarist
  class UrnResolver
    ELECTROPEDIA_BASE = "https://www.electropedia.org/iev/iev.nsf/display?openform&ievref="
    ISO_OBP_BASE = "https://www.iso.org/obp/ui/#"

    def initialize
      @schemes = {}
      register_default_schemes
    end

    def resolve(urn_or_reference)
      urn = to_urn(urn_or_reference)
      return nil unless urn

      _, resolver = @schemes.find { |prefix, _| urn.start_with?(prefix) }
      resolver&.call(urn)
    end

    def register_scheme(prefix, &block)
      @schemes[prefix] = block
    end

    class << self
      def instance
        @instance ||= new
      end

      def resolve(urn_or_reference)
        instance.resolve(urn_or_reference)
      end
    end

    private

    def register_default_schemes
      register_scheme("urn:iec:std:iec:60050") do |urn|
        resolve_iec(urn)
      end

      register_scheme("urn:iso:") do |urn|
        resolve_iso(urn)
      end
    end

    def resolve_iec(urn)
      code = extract_iec_code(urn)
      return nil unless code

      "#{ELECTROPEDIA_BASE}#{CGI.escape(code)}"
    end

    def extract_iec_code(urn)
      m = urn.match(/#con-([\d-]+)/) || urn.match(/\Aurn:iec:std:iec:60050-([\d-]+)/)
      m&.[](1)
    end

    def resolve_iso(urn)
      path = urn.delete_prefix("urn:")
      "#{ISO_OBP_BASE}#{path}"
    end

    def to_urn(urn_or_reference)
      case urn_or_reference
      when String then urn_or_reference
      when ConceptReference then concept_reference_to_urn(urn_or_reference)
      end
    end

    def concept_reference_to_urn(ref)
      return ref.urn if ref.urn && !ref.urn.strip.empty?
      return nil unless ref.external?
      return nil unless ref.source && ref.concept_id

      case ref.source
      when /\Aurn:iec/ then "#{ref.source}-#{ref.concept_id}"
      when /\Aurn:iso/ then "#{ref.source}:term:#{ref.concept_id}"
      else "#{ref.source}/#{ref.concept_id}"
      end
    end
  end
end
