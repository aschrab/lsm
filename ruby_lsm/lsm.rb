#!/usr/bin/ruby

require 'date'

class LSM_Error < Exception
  class NoEntry < self; end
  class BadLine< self; end
  class UnknownField < self; end
  class InvalidDate < self; end
  class MissingFields < self; end
end

class LSM_Entry
  REQUIRED = %w{ title version entered_date description primary_site }
  FIELDS = REQUIRED + %w{ keywords author maintained_by www_site alternate_site
    original_site platforms copying_policy checked_status checked_date }

  attr_accessor :completed, *FIELDS

  def initialize
  end

  def check_required
    missing = []
    REQUIRED.each do |field|
      missing << field unless send field
    end
    raise LSM_Error::MissingFields, missing.join(', ') if missing.length > 0
  end

  def entered_date= dt
    dt = dt.chomp.strip
    begin
      edate = Date.strptime dt, '%Y-%m-%d'
    rescue Exception
      raise LSM_Error::InvalidDate, "'#{dt}'"
    end
    @entered_date = edate
  end

  def from_file( file )
    # Search for beginning of entry
    file.each do |line|
      case line
      when /^Begin4/; break
      when nil; raise LSM_Error::NoEntry, "No entry found"
      end
    end

    # Read content into an Array
    lines = []
    file.each do |line|
      case line
      when /^End\s*$/
        completed = true
        break
      else
        lines << line
      end
    end

    while line = lines.shift
      case line
      when /^([a-z-]+):\s*(.*)/im
        field, content = $1, $2
        while lines[0] and lines[0][/^(\s+(.*)|$)/m]
          content << $1
          lines.shift
        end
        field = field.downcase.gsub /-/, '_'
        raise LSM_Error::UnknownField, field unless FIELDS.include? field
        send "#{field}=", content.chomp.strip
      when /^\s*$/
      else
        raise LSM_Error::BadLine
      end
    end

    check_required

    self
  end
end

if $0 == __FILE__
  require 'yaml'
  entry = LSM_Entry.new.from_file( $stdin )
  entry.to_yaml
end
