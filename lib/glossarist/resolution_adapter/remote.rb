# frozen_string_literal: true

require "net/http"
require "json"

module Glossarist
  class ResolutionAdapter
    class Remote < ResolutionAdapter
      attr_reader :uri_prefix, :endpoint, :cache

      def initialize(uri_prefix:, endpoint:)
        super()
        @uri_prefix = uri_prefix
        @endpoint = endpoint.chomp("/")
        @cache = {}
      end

      def resolve(reference)
        return nil unless reference.ref_type == "urn"
        return nil unless reference.source == uri_prefix

        key = cache_key(reference)
        return @cache[key] if @cache.key?(key)

        @cache[key] = fetch(reference)
      end

      private

      def build_uri(reference)
        URI.parse("#{endpoint}/#{URI.encode_www_form_component(reference.source)}/#{URI.encode_www_form_component(reference.concept_id)}")
      end

      def parse_response(response)
        content_type = response["content-type"].to_s
        if content_type.include?("json")
          JSON.parse(response.body)
        elsif content_type.include?("yaml")
          ConceptDocument.from_yamls(response.body).to_managed_concept
        else
          ManagedConcept.from_yaml(response.body)
        end
      end

      def cache_key(reference)
        "#{reference.source}/#{reference.concept_id}"
      end

      def fetch(reference)
        uri = build_uri(reference)
        response = Net::HTTP.get_response(uri)
        return nil unless response.is_a?(Net::HTTPSuccess)

        parse_response(response)
      rescue StandardError
        nil
      end
    end
  end
end
