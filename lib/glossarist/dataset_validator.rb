# frozen_string_literal: true

module Glossarist
  class DatasetValidator
    def validate(path, strict: false, reference_path: nil)
      if File.extname(path).downcase == ".gcr"
        validate_gcr(path, reference_path: reference_path)
      else
        validate_directory(path, reference_path: reference_path)
      end
    end

    private

    def validate_gcr(path, reference_path: nil)
      result = GcrValidator.new.validate(path)

      if reference_path
        ref_result = validate_gcr_cross_references(path, reference_path)
        result.merge(ref_result)
      end

      result
    end

    def validate_directory(path, reference_path: nil)
      result = ConceptValidator.new(path).validate_all

      if reference_path
        ref_result = validate_directory_cross_references(path, reference_path)
        result.merge(ref_result)
      end

      result
    end

    def validate_gcr_cross_references(path, reference_path)
      extractor = ReferenceExtractor.new
      resolver = build_resolver(reference_path)
      pkg = GcrPackage.load(path)
      uri_prefix = pkg.metadata&.dig("uri_prefix") || pkg.metadata&.dig("shortname")
      resolver.register_self(pkg.concepts)
      resolver.register_package(pkg, uri_prefix: uri_prefix)
      resolver.validate_all(pkg, extractor: extractor)
    end

    def validate_directory_cross_references(path, reference_path)
      extractor = ReferenceExtractor.new
      resolver = build_resolver(reference_path)
      concepts = ConceptCollector.collect(path)
      resolver.register_self(concepts)
      resolver.validate_all(concepts, extractor: extractor)
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
  end
end
