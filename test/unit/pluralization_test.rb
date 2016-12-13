require File.expand_path('../../test_helper', __FILE__)

class PluralizationTest < ActiveSupport::TestCase
  should 'return one' do
    assert_equal 'one', Pluralization.pluralize(1, 'one', 'few', 'many', 'other')
  end

  should 'return few' do
    assert_equal 'few', Pluralization.pluralize(2, 'one', 'few', 'many', 'other')
  end

  should 'return many' do
    assert_equal 'many', Pluralization.pluralize(5, 'one', 'few', 'many', 'other')
  end

  should 'return other' do
    assert_equal 'other', Pluralization.pluralize(1.5, 'one', 'few', 'many', 'other')
  end
end
