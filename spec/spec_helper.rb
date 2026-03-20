# frozen_string_literal: true

# Require liquid before stubbing Jekyll so its constants are properly set up
require 'liquid'

# Stub Jekyll constants so we can load the plugin without a full Jekyll install
# in a bare RSpec run.
unless defined?(Jekyll)
  module Jekyll
    def self.logger
      @logger ||= begin
        require 'logger'
        l = Logger.new($stdout)
        l.level = Logger::FATAL
        l
      end
    end

    class Generator
      def self.safe(_val); end
      def self.priority(_val); end
    end

    module Converters
      class Markdown; end
    end

    module Hooks
      def self.register(*); end
    end
  end
end

require 'octicons'
require 'cssminify'
require_relative '../lib/jekyll-gfm-admonitions'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
end
