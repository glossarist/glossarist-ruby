RSpec.describe "Serialization and deserialization" do
  it "correctly loads concepts from files and writes them too" do
    collection = Glossarist::Collection.new(path: fixtures_path)
    collection.load_concepts

    zeus = collection["123-01"]
    hera = collection["123-02"]

    expect([zeus, hera]).to all be_kind_of(Glossarist::Concept)
    expect([zeus.l10n("eng"), zeus.l10n("deu"), hera.l10n("eng"),
      hera.l10n("deu")]).to all be_kind_of(Glossarist::LocalizedConcept)

    expect(zeus.l10n("eng").designations.first["designation"]).to eq("Zeus")
    expect(hera.l10n("eng").designations.first["designation"]).to eq("Hera")
    expect(zeus.l10n("eng").superseded_concepts.size).to eq(1)
    expect(hera.l10n("eng").superseded_concepts.size).to eq(0)

    Dir.mktmpdir do |tmp_path|
      collection.path = tmp_path
      collection.save_concepts
      system "diff", fixtures_path, tmp_path
      expect($?.exitstatus).to eq(0) # no difference
    end
  end
end
