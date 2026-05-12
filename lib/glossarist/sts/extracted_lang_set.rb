# frozen_string_literal: true

module Glossarist
  module Sts
    ExtractedLangSet = Struct.new(
      :language_code,
      :definition_text,
      :note_texts,
      :example_texts,
      :source_texts,
      :domain,
      :designations,
      keyword_init: true,
    )
  end
end
