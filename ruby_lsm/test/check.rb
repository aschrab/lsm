#!/usr/bin/ruby

require 'test/unit'
require 'lsm'

$dir = 'test/files'

class TestCheck < Test::Unit::TestCase
  def test_good
    entry = File.open("#{$dir}/good.lsm"){ |f| LSM_Entry.new.from_file f }
    assert_equal( 'lsmtool', entry.title )
    assert_equal( '0.7', entry.version )
    assert_equal( 'GPL', entry.copying_policy )
    assert_equal( '19 July 1995', entry.entered_date.strftime('%d %B %Y') )
    assert_equal( 'Linux Software Map, LSM, browser', entry.keywords )
    assert_equal( 'lars.wirzenius@helsinki.fi (Lars Wirzenius)', entry.author )

    assert_equal "sunsite.unc.edu  /pub/Linux/apps/databases
		lsmtool-0.6.tar.gz", entry.primary_site

    assert_equal "Linux, but should work on any Unix box with curses and ANSI C.
		Requires my Publib library, which can be found in
		ftp://ftp.cs.helsinki.fi/pub/Software/Local/Publib/ .", entry.platforms

    assert_equal "Tools for browsing and updating an LSM database and for checking
  the validity of LSM entries (also: for maintaining the LSM).  This version switches to raw termcap (curses stinks).

		It is ok to have empty lines inside the body.", entry.description
  end
end