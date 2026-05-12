# frozen_string_literal: true

module Glossarist
  module Sts
    ExtractedTerm = Struct.new(
      :id,
      :label,
      :source_ref,
      :lang_sets,
      keyword_init: true,
    )
  end
end
