# frozen_string_literal: true

require_relative "../context_configuration"

module Glossarist
  module V3
    module Configuration
      extend Glossarist::ContextConfiguration

      CONTEXT_ID = :glossarist_v3
    end
  end
end
