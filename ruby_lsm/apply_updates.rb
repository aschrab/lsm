#!/usr/bin/ruby -w

abort "Usage: #$0 <update_file> <input_file> <output_file>" if ARGV.length < 3

require "#{File.dirname $0}/lsm.rb"

new_entries = {}

output_file = File.new( ARGV.pop, 'w' )
input_file = ARGV.pop

ARGV.each do |file|
  File.open(file) do |f|
    LSM_Entry.each(f) do |entry|
	if entry.has_errors?
	  $stderr.puts entry.report_errors
	  exit
	else
	  new_entries[entry.title.downcase] = entry
	end
    end
  end
end

File.open(input_file) do |input_file|
  LSM_Entry.each(input_file) do |entry|
    if new_entries[ entry.title.downcase ]
      entry = new_entries.delete entry.title.downcase
    end

    output_file.puts entry.format
    output_file.puts
  end
end

new_entries.each do |title,entry|
  output_file.puts entry.format
  output_file.puts
end
