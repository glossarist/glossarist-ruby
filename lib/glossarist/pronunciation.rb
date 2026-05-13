module Glossarist
  # A pronunciation or transcription of a designation, following ISO 24229
  # spelling system conventions.
  #
  # Each pronunciation entry specifies the text of the pronunciation and the
  # context in which it is expressed:
  # - +language+ (ISO 639) identifies the language or dialect being pronounced
  # - +script+ (ISO 15924) identifies the script used for the pronunciation text
  # - +country+ (ISO 3166-1) identifies the country variant
  # - +system+ identifies the transcription/romanization system used (ISO 24229
  #   conversion system code or a simple identifier like "IPA")
  #
  # A designation can have multiple pronunciations, e.g.:
  #   - IPA:       { content: "toːkjoː", script: "Latn", language: "jpn", system: "IPA" }
  #   - Hepburn:   { content: "Tōkyō",   script: "Latn", language: "jpn", system: "Var:jpn-Hrkt:Latn:Hepburn-1886" }
  #   - Cyrillic:  { content: "Токио",   script: "Cyrl", language: "rus", system: "polivanov" }
  class Pronunciation < Lutaml::Model::Serializable
    attribute :content, :string
    attribute :language, :string
    attribute :script, :string
    attribute :country, :string
    attribute :system, :string

    key_value do
      map :content, to: :content
      map :language, to: :language
      map :script, to: :script
      map :country, to: :country
      map :system, to: :system
    end
  end
end
