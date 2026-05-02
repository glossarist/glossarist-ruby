# frozen_string_literal: true

require "yaml"

module Glossarist
  class ReferenceResolver
    def initialize
      @local_adapter = nil
      @package_adapters = []
      @route_adapter = ResolutionAdapter::Route.new
      @remote_adapters = []
    end

    def register_self(concepts)
      @local_adapter = ResolutionAdapter::Local.new(concepts)
    end

    def register_package(package_or_concepts, uri_prefix: nil)
      concepts = extract_concepts(package_or_concepts)
      prefix = uri_prefix || infer_uri_prefix(package_or_concepts)
      raise ArgumentError, "uri_prefix required" unless prefix

      @package_adapters << ResolutionAdapter::Package.new(concepts, uri_prefix: prefix)
    end

    def add_route(from:, to:)
      @route_adapter.add(from: from, to: to)
    end

    def register_remote(uri_prefix:, endpoint:)
      @remote_adapters << ResolutionAdapter::Remote.new(uri_prefix: uri_prefix, endpoint: endpoint)
    end

    def resolve(reference)
      # 1. Local resolution (intra-set)
      if reference.local?
        return @local_adapter&.resolve(reference)
      end

      # 2. Apply route overrides
      routed_ref = apply_routes(reference)

      # 3. Try package adapters (co-loaded GCRs)
      @package_adapters.each do |adapter|
        result = adapter.resolve(routed_ref)
        return result if result
      end

      # 4. Try remote adapters
      @remote_adapters.each do |adapter|
        result = adapter.resolve(routed_ref)
        return result if result
      end

      nil
    end

    def resolve_all(concept_hash, extractor: nil)
      extractor ||= ReferenceExtractor.new
      refs = extractor.extract_from_concept_hash(concept_hash)
      refs.map { |ref| [ref, resolve(ref)] }
    end

    def validate_all(package_or_concepts, extractor: nil, mode: :multi)
      concepts = extract_concepts(package_or_concepts)
      extractor ||= ReferenceExtractor.new
      result = ValidationResult.new

      concepts.each do |concept|
        refs = extractor.extract_from_concept_hash(concept)
        termid = concept["termid"] || concept["id"]

        refs.each do |ref|
          resolved = resolve(ref)
          if resolved.nil?
            scope = ref.local? ? "intra-set" : "inter-set (#{ref.source})"
            result.add_warning("#{termid}: Unresolvable #{scope} reference: #{ref.term} -> #{ref.concept_id}")
          end
        end

        if mode == :single && !@local_adapter
          external_refs = refs.select(&:external?)
          if external_refs.any?
            result.add_warning("#{termid}: #{external_refs.size} external reference(s) not checked in single mode")
          end
        end
      end

      result
    end

    def load_collection(collection_dir)
      config_path = File.join(collection_dir, "collection.yaml")
      if File.exist?(config_path)
        load_collection_config(config_path, collection_dir)
      else
        load_gcr_directory(collection_dir)
      end
    end

    def registered_datasets
      @package_adapters.map(&:uri_prefix)
    end

    private

    def apply_routes(reference)
      routed = @route_adapter.resolve(reference)
      routed || reference
    end

    def extract_concepts(package_or_concepts)
      case package_or_concepts
      when GcrPackage then package_or_concepts.concepts
      when Array then package_or_concepts
      when Hash then [package_or_concepts]
      else raise ArgumentError, "Expected GcrPackage, Array, or Hash"
      end
    end

    def infer_uri_prefix(package_or_concepts)
      case package_or_concepts
      when GcrPackage then package_or_concepts.metadata&.dig("uri_prefix")
      end
    end

    def load_collection_config(config_path, collection_dir)
      config = YAML.safe_load(File.read(config_path),
                              permitted_classes: [Date, Time])

      Array(config["packages"]).each do |pkg|
        gcr_path = File.join(collection_dir, pkg["file"])
        next unless File.exist?(gcr_path)

        gcr = GcrPackage.load(gcr_path)
        prefix = pkg["uri_prefix"] || gcr.metadata&.dig("uri_prefix")
        register_package(gcr, uri_prefix: prefix)
      end

      Array(config["routes"]).each do |route|
        add_route(from: route["from"], to: route["to"])
      end

      Array(config["remote"]).each do |remote|
        register_remote(uri_prefix: remote["uri_prefix"], endpoint: remote["endpoint"])
      end
    end

    def load_gcr_directory(dir)
      Dir.glob(File.join(dir, "*.gcr")).each do |gcr_path|
        pkg = GcrPackage.load(gcr_path)
        prefix = pkg.metadata&.dig("uri_prefix")
        register_package(pkg, uri_prefix: prefix)
      end
    end
  end
end
