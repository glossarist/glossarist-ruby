# frozen_string_literal: true

module Glossarist
  module Errors
    # Raised by CLI command classes on invalid usage or failed runs.
    # Library classes stay exception-only; exe/glossarist owns the
    # process exit code. Calling exit from a command class would kill
    # any host process exercising it in-process (glossarist-ruby#248).
    class CliError < Base
    end
  end
end
