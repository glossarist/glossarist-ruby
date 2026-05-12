# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Glossarist::Validation::AssetIndex do
  subject(:index) { described_class.new }

  describe "#register and #resolve?" do
    it "registers and resolves a path" do
      index.register("images/foo.png")
      expect(index.resolve?("images/foo.png")).to be true
    end

    it "strips leading slash when normalizing" do
      index.register("/images/bar.png")
      expect(index.resolve?("images/bar.png")).to be true
    end

    it "returns false for unregistered paths" do
      expect(index.resolve?("nonexistent.png")).to be false
    end
  end

  describe "#each_path" do
    it "yields each registered path" do
      index.register("images/a.png")
      index.register("images/b.png")
      paths = []
      index.each_path { |p| paths << p }
      expect(paths).to contain_exactly("images/a.png", "images/b.png")
    end
  end

  describe ".build_from_directory" do
    it "indexes image files from the images/ directory" do
      Dir.mktmpdir do |dir|
        images_dir = File.join(dir, "images")
        FileUtils.mkdir_p(images_dir)
        File.write(File.join(images_dir, "logo.png"), "data")

        index = described_class.build_from_directory(dir)
        expect(index.resolve?("images/logo.png")).to be true
      end
    end

    it "indexes graphical symbol images from concept terms" do
      Dir.mktmpdir do |dir|
        concepts_dir = File.join(dir, "concepts")
        FileUtils.mkdir_p(concepts_dir)
        concept = {
          "termid" => "1",
          "eng" => {
            "terms" => [{ "type" => "graphical_symbol",
                          "image" => "images/symbol.svg" }],
            "definition" => [{ "content" => "def" }],
            "entry_status" => "valid",
          },
        }
        File.write(File.join(concepts_dir, "1.yaml"), YAML.dump(concept))

        index = described_class.build_from_directory(dir)
        expect(index.resolve?("images/symbol.svg")).to be true
      end
    end

    it "returns empty index when no images directory or concepts exist" do
      Dir.mktmpdir do |dir|
        index = described_class.build_from_directory(dir)
        expect(index.paths).to be_empty
      end
    end
  end

  describe ".build_from_zip" do
    it "indexes image entries from the ZIP" do
      Dir.mktmpdir do |dir|
        gcr_path = File.join(dir, "test.gcr")
        mc = Glossarist::ManagedConcept.new(data: { id: "1" })
        l10n = Glossarist::LocalizedConcept.of_yaml({
                                                      "data" => {
                                                        "language_code" => "eng",
                                                        "terms" => [{
                                                          "type" => "expression", "designation" => "test"
                                                        }],
                                                        "definition" => [{ "content" => "def" }],
                                                      },
                                                    })
        mc.add_localization(l10n)
        metadata = Glossarist::GcrMetadata.new(
          shortname: "test", version: "1.0.0",
          concept_count: 1, languages: ["eng"], schema_version: "1",
          uri_prefix: "urn:test"
        )
        Glossarist::GcrPackage.create(
          concepts: [mc], metadata: metadata,
          register_data: nil, output_path: gcr_path
        )

        Zip::File.open(gcr_path, create: false) do |zf|
          zf.get_output_stream("images/logo.png") { |f| f.write("data") }
        end

        index = described_class.build_from_zip(gcr_path)
        expect(index.resolve?("images/logo.png")).to be true
      end
    end
  end
end
