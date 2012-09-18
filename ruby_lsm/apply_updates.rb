#!/usr/bin/ruby -w

abort "Usage: #$0 <update_file> <input_file> <output_file>" if ARGV.length < 3

require "#{File.dirname $0}/lsm.rb"

new_entries = {}

output = File.new( ARGV.pop, 'w' )
original_file = ARGV.pop

ARGV.each do |update_file|
  File.open(update_file) do |update|
    LSM::Entry.each(update) do |entry|
      if entry.has_errors?
        $stderr.puts entry.report_errors
        exit
      else
        new_entries[entry.title.downcase] = entry
      end
    end
  end
end

File.open(original_file) do |original|
  LSM::Entry.each(original) do |entry|
    if new_entries[ entry.title.downcase ]
      entry = new_entries.delete entry.title.downcase
    end

    output.puts entry.format
    output.puts
  end
end

new_entries.each do |title,entry|
  output.puts entry.format
  output.puts
end
