# frozen_string_literal: true

RSpec.describe Glossarist::ManagedConceptCollection do
  let(:managed_concept_collection) { Glossarist::ManagedConceptCollection.new }

  describe "#managed_concepts" do
    it "returns an array of managed concepts" do
      managed_concept = Glossarist::ManagedConcept.of_yaml("data" => { id: "id" })
      managed_concept_collection.store(managed_concept)

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end

  describe "#managed_concepts=" do
    it "sets managed concepts" do
      managed_concept = Glossarist::ManagedConcept.of_yaml("data" => { id: "id" })
      managed_concept_collection.managed_concepts = [managed_concept]

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end

  describe "#to_h" do
    it "returns a hash" do
      managed_concept_collection.store(Glossarist::ManagedConcept.of_yaml("data" => { id: "id" }))

      expect(managed_concept_collection.to_h).to eq(
        "managed_concepts" => [
          {
            "data" => { "identifier" => "id" },
            "id" => "f05ee7c5-ba30-5162-9a63-0831726ca83e",
          },
        ],
      )
    end
  end

  describe "#each" do
    it "iterates over managed concepts" do
      managed_concept_collection.store(Glossarist::ManagedConcept.of_yaml("data" => { id: "id" }))

      expect { |b| managed_concept_collection.each(&b) }
        .to yield_control.once
    end
  end

  describe "#fetch" do
    let(:managed_concept) do
      Glossarist::ManagedConcept.of_yaml("data" => { id: "id" })
    end

    it "fetches a managed concept by id" do
      managed_concept_collection.store(managed_concept)
      expect(managed_concept_collection.fetch("id")).to eq(managed_concept)
    end

    it "fetches a managed concept by uuid" do
      managed_concept_collection.store(managed_concept)
      uuid = Glossarist::Utilities::UUID.uuid_v5(
        Glossarist::Utilities::UUID::OID_NAMESPACE, managed_concept.to_yaml(except: [:uuid])
      )

      expect(managed_concept_collection.fetch(uuid)).to eq(managed_concept)
    end
  end

  describe "#[]" do
    let(:managed_concept) do
      Glossarist::ManagedConcept.of_yaml("data" => { id: "id" })
    end

    it "returns a managed concept by uuid" do
      managed_concept_collection.store(managed_concept)
      uuid = Glossarist::Utilities::UUID.uuid_v5(
        Glossarist::Utilities::UUID::OID_NAMESPACE, managed_concept.to_yaml(except: [:uuid])
      )

      expect(managed_concept_collection[uuid]).to eq(managed_concept)
    end

    it "returns a managed concept by id" do
      managed_concept_collection.store(managed_concept)

      expect(managed_concept_collection["id"]).to eq(managed_concept)
    end
  end

  describe "#fetch_or_initialize" do
    it "add a managed concept when not present" do
      expect { managed_concept_collection.fetch_or_initialize("new") }
        .to change { managed_concept_collection.fetch("new") }
        .from(nil)
        .to(Glossarist::ManagedConcept)
    end

    it "add and return a managed concept when not present" do
      expect(managed_concept_collection.fetch_or_initialize("new"))
        .to be_an_instance_of(Glossarist::ManagedConcept)
    end

    it "returns a managed concept when present" do
      managed_concept_collection.store(Glossarist::ManagedConcept.of_yaml(data: { id: "new" }))

      expect { managed_concept_collection.fetch_or_initialize("new") }
        .not_to(change { managed_concept_collection.fetch("new") })
    end
  end

  describe "#store" do
    it "adds a managed concept" do
      managed_concept = Glossarist::ManagedConcept.of_yaml("data" => { id: "id" })
      managed_concept_collection.store(managed_concept)

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end

  describe "#<<" do
    it "adds a managed concept" do
      managed_concept = Glossarist::ManagedConcept.of_yaml({
                                                             "data" => { "id" => "id" },
                                                           })
      managed_concept_collection << managed_concept

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end

  describe "#by_id_and" do
    let(:collection) { described_class.new }

    it "matches on id alone when version is nil" do
      c = Glossarist::ManagedConcept.of_yaml("data" => { "id" => "uuid-1" })
      c.version = nil
      collection.store(c)
      expect(collection.by_id_and(c.uuid, nil)).to eq(c)
    end

    it "matches on id alone when version is omitted" do
      c = Glossarist::ManagedConcept.of_yaml("data" => { "id" => "uuid-1" })
      collection.store(c)
      expect(collection.by_id_and(c.uuid)).to eq(c)
    end

    it "matches on id and version together" do
      c2010 = Glossarist::ManagedConcept.of_yaml("data" => { "id" => "shared-id" })
      c2010.version = "2010"
      c2024 = Glossarist::ManagedConcept.of_yaml("data" => { "id" => "shared-id2" })
      c2024.version = "2024"
      collection.store(c2010)
      collection.store(c2024)
      expect(collection.by_id_and(c2024.uuid, "2024")).to eq(c2024)
    end

    it "returns nil when no concept has the (id, version) pair" do
      c = Glossarist::ManagedConcept.of_yaml("data" => { "id" => "uuid-1" })
      c.version = "2010"
      collection.store(c)
      expect(collection.by_id_and(c.uuid, "2030")).to be_nil
    end

    it "returns nil when no concept has the id" do
      expect(collection.by_id_and("anything", "2024")).to be_nil
    end

    it "returns nil when version is set but concept version is nil" do
      c = Glossarist::ManagedConcept.of_yaml("data" => { "id" => "uuid-1" })
      collection.store(c)
      expect(collection.by_id_and(c.uuid, "2024")).to be_nil
    end

    it "looks up by data id when no uuid match" do
      c = Glossarist::ManagedConcept.of_yaml("data" => { "id" => "my-concept" })
      c.version = "v1"
      collection.store(c)
      expect(collection.by_id_and("my-concept", "v1")).to eq(c)
    end
  end

  describe "#load_from_files" do
    context "Invalid concepts" do
      let(:invalid_concepts_path) { fixtures_path("invalid_concepts") }

      it "skips invalid YAML files without raising" do
        expect do
          managed_concept_collection.load_from_files(invalid_concepts_path)
        end.not_to raise_error
      end
    end

    context "Valid concepts" do
      let(:valid_concepts_path) { fixtures_path("concept_collection_v2") }

      it "will not raise Glossarist::Errors::Parse" do
        expect do
          managed_concept_collection.load_from_files(valid_concepts_path)
        end.not_to raise_error
      end

      it "will read concepts correctly from file" do
        expect do
          managed_concept_collection.load_from_files(valid_concepts_path)
        end.to change { managed_concept_collection.count }.by(4)
      end
    end

    context "concepts/ layout with one document per language" do
      let(:dataset) do
        <<~YAML
          ---
          data:
            identifier: "1"
            localized_concepts:
              eng: l10n-eng
              fra: l10n-fra
          status: valid
          schema_version: '3'
          id: concept-1
          ---
          data:
            language_code: eng
            entry_status: valid
          id: l10n-eng
          ---
          data:
            language_code: fra
            entry_status: valid
          id: l10n-fra
        YAML
      end

      it "loads each language document exactly once" do
        Dir.mktmpdir do |dir|
          FileUtils.mkdir_p(File.join(dir, "concepts"))
          File.write(File.join(dir, "concepts", "concept-1.yaml"), dataset)
          managed_concept_collection.load_from_files(dir)

          l10ns = managed_concept_collection.flat_map { |mc| mc.localizations.values }
          expect(l10ns.map(&:language_code)).to contain_exactly("eng", "fra")
        end
      end
    end

    context "with classes registered in Config" do
      let(:managed_class) { Class.new(Glossarist::ManagedConcept) }
      let(:localized_class) { Class.new(Glossarist::LocalizedConcept) }
      let(:default_load) do
        described_class.new.tap do |collection|
          collection.load_from_files(fixtures_path("concept_collection_v2"))
        end
      end

      before do
        @registered_classes = Glossarist::Config.instance.registered_classes.dup
        Glossarist::Config.register_class(:managed_concept, managed_class)
        Glossarist::Config.register_class(:localized_concept, localized_class)
        managed_concept_collection.load_from_files(
          fixtures_path("concept_collection_v2"),
        )
      end

      after do
        Glossarist::Config.instance
          .instance_variable_set(:@registered_classes, @registered_classes)
      end

      it "builds managed concepts with the registered class" do
        expect(managed_concept_collection.map(&:class).uniq)
          .to eq([managed_class])
      end

      it "builds localizations with the registered class" do
        classes = managed_concept_collection
          .flat_map { |mc| mc.localizations.values.map(&:class) }.uniq

        expect(classes).to eq([localized_class])
      end

      it "keeps the content of every concept" do
        Glossarist::Config.instance
          .instance_variable_set(:@registered_classes, @registered_classes)

        expect(managed_concept_collection.map(&:to_yaml_hash))
          .to eq(default_load.map(&:to_yaml_hash))
      end

      it "keeps the content of every localization" do
        Glossarist::Config.instance
          .instance_variable_set(:@registered_classes, @registered_classes)
        hashes = ->(coll) { coll.flat_map { |mc| mc.localizations.values.map(&:to_yaml_hash) } }

        expect(hashes.call(managed_concept_collection))
          .to eq(hashes.call(default_load))
      end
    end
  end
end
