# frozen_string_literal: true

require "json"
require "fileutils"
require "net/http"
require "time"
require "uri"

module Glossarist
  module Tasks
    # Syncs vendored concept-model data artifacts from glossarist/concept-model.
    #
    # concept-model is a data-only repo (TTL, JSON-LD, YAML schemas). It is
    # not a gem. We vendor the small set of artifacts we need (shapes,
    # context, ontology) and load them at runtime via ShaclValidator.
    module SyncModel
      REPO = "glossarist/concept-model"
      OUT_DIR = File.expand_path("data/concept-model", File.join(__dir__, "..", "..", ".."))

      TARGETS = {
        "prefixes.ttl" => %w[
          ontologies/prefixes.ttl
          prefixes.ttl
        ].freeze,
        "glossarist.context.jsonld" => %w[
          ontologies/glossarist.context.jsonld
          glossarist.context.jsonld
        ].freeze,
        "glossarist.ttl" => %w[
          ontologies/glossarist.ttl
          glossarist.ttl
        ].freeze,
        "shapes/glossarist.shacl.ttl" => %w[
          ontologies/shapes/glossarist.shacl.ttl
          shapes/glossarist.shacl.ttl
        ].freeze,
      }.freeze

      class << self
        def call(ref: nil)
          ref ||= latest_tag
          FileUtils.mkdir_p(File.join(OUT_DIR, "shapes"))

          TARGETS.each do |out_rel, candidates|
            content = fetch_any(ref, candidates)
            out_path = File.join(OUT_DIR, out_rel)
            FileUtils.mkdir_p(File.dirname(out_path))
            File.write(out_path, content)
            puts "  ✓ #{out_rel} (#{content.length} bytes)"
          end

          write_source_manifest(ref)
          puts "\nSynced #{TARGETS.length} file(s) from #{REPO}@#{ref}."
        end

        private

        def latest_tag
          url = URI("https://api.github.com/repos/#{REPO}/releases/latest")
          req = Net::HTTP::Get.new(url)
          req["Accept"] = "application/vnd.github+json"
          JSON.parse(Net::HTTP.start(url.hostname, url.port, use_ssl: true) { |http| http.request(req) }.body)
            .fetch("tag_name")
        rescue StandardError => e
          warn "Could not determine latest concept-model tag: #{e.message}"
          exit 1
        end

        def fetch_any(ref, candidates)
          candidates.each do |path|
            begin
              return fetch_file(ref, path)
            rescue StandardError
              next
            end
          end
          raise "Could not fetch any of: #{candidates.join(', ')}"
        end

        def fetch_file(ref, path)
          url = URI("https://raw.githubusercontent.com/#{REPO}/#{ref}/#{path}")
          Net::HTTP.get(url)
        end

        def write_source_manifest(ref)
          manifest = {
            "repo" => REPO,
            "ref" => ref,
            "syncedAt" => Time.now.utc.iso8601,
          }
          File.write(File.join(OUT_DIR, "SOURCE.json"),
                     JSON.pretty_generate(manifest) + "\n")
        end
      end
    end
  end
end
