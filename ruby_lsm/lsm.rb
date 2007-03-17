#!/usr/bin/ruby

require 'date'

class LSM_Error < Exception
  class NoEntry < self; end
  class BadLine< self; end
  class UnknownField < self; end
  class InvalidDate < self
    def explanation field, content
      [
        "field '#{field}' contains invalid date '#{content}'"
      ]
    end
  end
  class MissingFields < self; end
end

class LSM_Entry
  REQUIRED = %w{ title version entered_date description primary_site }
  FIELDS = REQUIRED + %w{ keywords author maintained_by www_site alternate_site
    original_site platforms copying_policy checked_status checked_date }

  attr_accessor :completed, *FIELDS

  attr_reader :lines

  def initialize
    @errors = {}
  end

  def has_errors?
    @errors.size > 0 or missing_fields
  end

  def missing_fields
    missing = []
    REQUIRED.each do |field|
      missing << field if send(field).nil?
    end
    missing.length > 0 ? missing : nil
  end

  def entered_date= dt
    @entered_date = false
    @entered_date = parse_date dt
  end

  def parse_date dt
    dt = dt.chomp.strip
    raise LSM_Error::InvalidDate unless dt =~ /^\d{4}-\d{1,2}-\d{1,2}/
    begin
      return Date.strptime( dt, '%Y-%m-%d' )
    rescue Exception
      raise LSM_Error::InvalidDate
    end
  end

  def from_file file
    # Search for beginning of entry
    file.each do |line|
      case line
      when /^Begin4/; break
      when nil; raise LSM_Error::NoEntry, "No entry found"
      end
    end

    # Read content into an Array
    @lines = []
    file.each do |line|
      case line
      when /^End\s*$/
        completed = true
        break
      else
        lines << line
      end
    end

    line_num = -1
    while lines[line_num]
      line_num += 1
      current_line = line_num
      case lines[line_num]
      when /^([^:]+):\s*(.*)/im
        field, content = $1, $2

        if field[/\s$/]
          @errors[current_line] = [
            "No whitespace allowed between keyword and colon (sorry)" ]
          next
        end

        while lines[line_num+1] and lines[line_num+1][/^(\s+(.*)|$)/m]
          content << $1
          line_num+=1
        end
        field = field.downcase.gsub /-/, '_'
        if FIELDS.include? field
          content = content.chomp.strip
          begin
            send "#{field}=", content
          rescue LSM_Error
            @errors[current_line] = $!.explanation( field, content )
          end
        else
          @errors[current_line] = [ "Unknown keyword: #{field}" ]
        end
      when /^\s*$/
        # Ignore empty lines before first field
      else
        @errors[current_line] = [ "No keyword found",
          "  (lines beginning in column 1 must begin with a keyword)" ]
      end
    end

    self
  end

  def report_errors
    output = ''
    lines.each_with_index do |line,idx|
      output << '%2d: %s' % [ idx+1, line ]
    end

    output << "\n"

    (0...lines.length).each do |idx|
      if @errors[idx]
        @errors[idx].each do |err_line|
          output << "error #{idx+1}: #{err_line}\n"
        end
      end
    end

    (missing_fields or []).each do |field|
      field = field.gsub(/_/, '-').sub(/^([a-z])/){ $1.upcase }
      output << "error: Required header '#{field}' is missing\n"
    end

    output
  end
end

if $0 == __FILE__
  require 'yaml'
  entry = LSM_Entry.new.from_file( $stdin )
  puts entry.report_errors
end
