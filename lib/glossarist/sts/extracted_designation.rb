# frozen_string_literal: true

module Glossarist
  module Sts
    ExtractedDesignation = Struct.new(
      :term,
      :type,
      :normative_status,
      :part_of_speech,
      :abbreviation_type,
      keyword_init: true,
    )
  end
end
