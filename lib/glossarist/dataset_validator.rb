# frozen_string_literal: true

module Glossarist
  class DatasetValidator
    def validate(path, strict: false, reference_path: nil)
      result = validate_path(path)

      if reference_path
        ref_result = validate_cross_references(path, reference_path)
        result.merge(ref_result)
      end

      result
    end

    private

    def validate_path(path)
      if File.extname(path).downcase == ".gcr"
        validate_gcr(path)
      else
        validate_directory(path)
      end
    end

    def validate_gcr(path)
      GcrValidator.new.validate(path)
    end

    def validate_directory(path)
      ConceptValidator.new(path).validate_all
    end

    def validate_cross_references(path, reference_path)
      extractor = ReferenceExtractor.new
      resolver = build_resolver(reference_path)

      if File.extname(path).downcase == ".gcr"
        validate_gcr_refs(resolver, path, extractor)
      else
        validate_directory_refs(resolver, path, extractor)
      end
    end

    def build_resolver(reference_path)
      resolver = ReferenceResolver.new
      Dir.glob(File.join(reference_path, "*.gcr")).each do |gcr_path|
        pkg = GcrPackage.load(gcr_path)
        uri_prefix = pkg.metadata&.dig("uri_prefix") || pkg.metadata&.dig("shortname")
        resolver.register_package(pkg, uri_prefix: uri_prefix)
      end
      resolver
    end

    def validate_gcr_refs(resolver, path, extractor)
      pkg = GcrPackage.load(path)
      uri_prefix = pkg.metadata&.dig("uri_prefix") || pkg.metadata&.dig("shortname")
      resolver.register_self(pkg.concepts)
      resolver.register_package(pkg, uri_prefix: uri_prefix)
      resolver.validate_all(pkg, extractor: extractor)
    end

    def validate_directory_refs(resolver, path, extractor)
      concepts = ConceptCollector.collect(path)
      resolver.register_self(concepts)
      resolver.validate_all(concepts, extractor: extractor)
    end
  end
end
