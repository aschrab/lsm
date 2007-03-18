#!/usr/bin/ruby -w

abort "Usage: #$0 <update_file> <input_file> <output_file>" if ARGV.length < 3

require "#{File.dirname $0}/lsm.rb"

new_entries = {}

File.open(ARGV.shift) do |f|
  loop do
    begin
      entry = LSM_Entry.new.from_file f
    rescue LSM_Error::NoEntry
      break
    else
      if entry.has_errors?
        $stderr.puts entry.report_errors
        exit
      else
        new_entries[entry.title.downcase] = entry
      end
    end
  end
end

input_file = ARGV.shift
output_file = File.new( ARGV.shift, 'w' )

File.open(input_file) do |input_file|
  loop do
    begin
      entry = LSM_Entry.new.from_file input_file
    rescue LSM_Error::NoEntry
      break
    end

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
