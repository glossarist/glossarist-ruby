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
      tmpdir = Dir.mktmpdir
      gcr_path = File.join(tmpdir, "test.gcr")
      buffer = StringIO.new

      Zip::OutputStream.write_buffer(buffer) do |zos|
        zos.put_next_entry("metadata.yaml")
        zos.write(YAML.dump({ "shortname" => "test" }))
        zos.put_next_entry("images/logo.png")
        zos.write("data")
      end

      File.binwrite(gcr_path, buffer.string)
      GC.start

      index = described_class.build_from_zip(gcr_path)
      expect(index.resolve?("images/logo.png")).to be true
    ensure
      FileUtils.rm_rf(tmpdir)
    end
  end
end
