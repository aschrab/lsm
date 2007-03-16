#!/usr/bin/ruby

require 'test/unit'
require 'lsm'

$dir = 'test/files'

class TestCheck < Test::Unit::TestCase
  def test_good
    entry = File.open("#{$dir}/good.lsm"){ |f| LSM_Entry.new.from_file f }
    assert_equal( 'lsmtool', entry.title )
    assert_equal( '19 July 1995', entry.entered_date.strftime('%d %B %Y') )
  end
end
