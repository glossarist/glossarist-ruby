# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      module Registry
        @rules = []
        @mutex = Mutex.new

        def self.register(rule_class)
          @mutex.synchronize do
            @rules << rule_class unless @rules.include?(rule_class)
          end
        end

        def self.all
          @rules.map(&:new)
        end

        def self.for_category(category)
          all.select { |r| r.category == category }
        end

        def self.for_scope(scope)
          all.select { |r| r.scope == scope }
        end

        def self.find(code)
          all.find { |r| r.code == code }
        end

        def self.reset!
          @mutex.synchronize { @rules.clear }
        end

        def self.rule_classes
          @rules.dup
        end
      end
    end
  end
end
