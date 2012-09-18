#!/usr/bin/ruby

require 'test/unit'
require "#{File.dirname $0}/../lsm"

$dir = 'test/files'

class TestCheck < Test::Unit::TestCase
  def test_good
    entry = File.open("#{$dir}/good.lsm"){ |f| LSM::Entry.new.from_file f }
    assert_equal nil, entry.has_errors?
    assert_equal nil, entry.report_errors
    assert_equal nil, entry.missing_fields
    assert_equal Hash.new, entry.errors
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

  def test_missing_version
    entry = File.open("#{$dir}/missing_version.lsm"){ |f| LSM::Entry.new.from_file f }
    assert_not_nil entry.has_errors?
    assert_equal %w/version/, entry.missing_fields
    assert_match %r{Required header 'Version' is missing}, entry.report_errors
    assert_equal 'lsmtool', entry.title
    assert_equal 'GPL', entry.copying_policy
  end

  def test_bad_date
    entry = File.open("#{$dir}/bad_date.lsm"){ |f| LSM::Entry.new.from_file f }
    assert_not_nil entry.has_errors?
    assert_equal nil, entry.missing_fields
    assert_equal [2], entry.errors.keys
    assert_match %r{'Entered-date' contains invalid date '}, entry.report_errors
    assert_equal 'lsmtool', entry.title
    assert_equal 'GPL', entry.copying_policy
  end

  def test_invalid_author
    entry=File.open("#{$dir}/invalid_author.lsm"){|f| LSM::Entry.new.from_file f}
    assert_not_nil entry.has_errors?
    assert_equal nil, entry.missing_fields
    assert_equal [8], entry.errors.keys
    assert_match %r{'Author' does not seem to contain}, entry.report_errors
    assert_equal 'lsmtool', entry.title
    assert_equal 'GPL', entry.copying_policy
  end

  def test_no_keyword_line
    entry=File.open("#{$dir}/no_keyword_line.lsm"){|f| LSM::Entry.new.from_file f}
    assert_equal 'lsmtool', entry.title
    assert_equal 'GPL', entry.copying_policy

    assert_not_nil entry.has_errors?
    assert_equal nil, entry.missing_fields
    assert_equal [15], entry.errors.keys
    assert_equal ["No keyword found", "  (lines beginning in column 1 must begin with a keyword)"], entry.errors[15]
  end

  def test_unknown_keyword
    entry=File.open("#{$dir}/unknown_keyword_line.lsm"){|f| LSM::Entry.new.from_file f}
    assert_equal 'lsmtool', entry.title
    assert_equal 'GPL', entry.copying_policy

    assert_not_nil entry.has_errors?
    assert_equal nil, entry.missing_fields
    assert_equal [15], entry.errors.keys
    assert_equal [ "Unknown keyword: Unknown-keyword" ], entry.errors[15]
  end
end

# vim: fdm=syntax
