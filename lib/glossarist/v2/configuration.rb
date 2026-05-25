# frozen_string_literal: true

require_relative "../context_configuration"

module Glossarist
  module V2
    module Configuration
      extend Glossarist::ContextConfiguration

      CONTEXT_ID = :glossarist_v2
    end
  end
end
