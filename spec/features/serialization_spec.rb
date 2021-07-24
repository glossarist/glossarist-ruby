RSpec.describe "Serialization and deserialization" do
  it "correctly loads concepts from files and writes them too" do
    collection = Glossarist::Collection.new(path: fixtures_path)
    collection.load_concepts

    king = collection["chess-02-01"]
    queen = collection["chess-02-02"]
    rook = collection["chess-02-03"]

    expect([king, queen, rook]).to all be_kind_of(Glossarist::Concept)

    expect([
      king.l10n("eng"), king.l10n("pol"),
      queen.l10n("eng"), queen.l10n("pol"),
      rook.l10n("eng"), rook.l10n("pol"),
    ]).to all be_kind_of(Glossarist::LocalizedConcept)

    expect(king.l10n("eng").designations.first.designation).to eq("King")
    expect(queen.l10n("eng").designations.first.designation).to eq("Queen")
    expect(rook.l10n("eng").designations.first.designation).to eq("Rook")

    expect(king.l10n("eng").designations.last.designation)
      .to match(/\p{Symbol}/)
    expect(queen.l10n("eng").designations.last.designation)
      .to match(/\p{Symbol}/)
    expect(rook.l10n("eng").designations.last.designation)
      .to match(/\p{Symbol}/)

    expect(king.l10n("eng").sources[0]).to be_structured
    expect(king.l10n("eng").sources[0].source).to eq("Wikipedia")
    expect(king.l10n("eng").sources[0].id).to eq("King (chess)")
    expect(king.l10n("eng").sources[0].link).to start_with("https")

    expect(king.l10n("eng").superseded_concepts.size).to eq(1)
    expect(queen.l10n("eng").superseded_concepts.size).to eq(0)
    expect(rook.l10n("eng").superseded_concepts.size).to eq(0)

    Dir.mktmpdir do |tmp_path|
      collection.path = tmp_path
      collection.save_concepts
      system "diff", fixtures_path, tmp_path
      expect($?.exitstatus).to eq(0) # no difference
    end
  end
end
