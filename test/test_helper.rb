$VERBOSE = nil # for hide ruby warnings

# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')
require 'minitest/spec'

DatabaseCleaner.strategy = :transaction
DatabaseCleaner.clean_with(:truncation)

class Minitest::Spec
  around do |tests|
    DatabaseCleaner.cleaning(&tests)
  end
end

class ActiveSupport::TestCase
  # Add spec DSL
  extend Minitest::Spec::DSL
end
