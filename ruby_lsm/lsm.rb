#!/usr/bin/ruby

require 'date'

class LSM_Error < Exception #{{{
  class NoEntry < self; end
  class BadLine< self; end
  class UnknownField < self; end
  class InvalidDate < self #{{{
    def explanation field, content
      [
        "field '#{field}' contains invalid date '#{content}'"
      ]
    end
  end #}}}
  class InvalidEmail < self #{{{
    def explanation field, content
      [
        "field '#{field}' does not seem to contain",
        "  an e-mail address (no `@' character)"
      ]
    end
  end #}}}
  class MissingFields < self; end
end #}}}

class LSM_Entry #{{{
  def self.each(file)
    loop do
      begin
	yield self.new.from_file( file )
      rescue LSM_Error::NoEntry
	break
      end
    end
  end

  REQUIRED = %w{ title version entered_date description primary_site }
  FIELDS = REQUIRED + %w{ keywords author maintained_by www_site alternate_site
    original_site platforms copying_policy checked_status checked_date }

  attr_accessor :completed, *FIELDS

  attr_reader :lines, :errors

  def initialize #{{{
    @errors = {}
  end #}}}

  def has_errors? #{{{
    @errors.size > 0 or missing_fields
  end #}}}

  # Return Array of required fields that aren't present, or nil
  def missing_fields #{{{
    missing = []
    REQUIRED.each do |field|
      missing << field if send(field).nil?
    end
    missing.length > 0 ? missing : nil
  end #}}}

  # Set the Entered-date
  undef :entered_date=
  def entered_date= dt #{{{
    @entered_date = false
    @entered_date = parse_date dt
  end #}}}

  # Check/set Checked-date
  undef :checked_date=
  def checked_date= dt #{{{
    @checked_date = false
    @checked_date = parse_date dt
  end #}}}

  # Check/set Author
  undef :author=
  def author= auth #{{{
    if auth[/@/]
      @author = auth
    else
      @author = false
      raise LSM_Error::InvalidEmail
    end
  end #}}}

  # Check/set Maintained-by
  undef :maintained_by=
  def maintained_by= maint #{{{
    if maint[/@/]
      @maintained_by = maint
    else
      @maintained_by = false
      raise LSM_Error::InvalidEmail
    end
  end #}}}

  # Check an parse a date, returns a Date object if successful,
  # otherwise raises LSM_Error::InvalidDate
  def parse_date dt #{{{
    dt = dt.chomp.strip
    raise LSM_Error::InvalidDate unless dt =~ /^\d{4}-\d{1,2}-\d{1,2}/
    begin
      return Date.strptime( dt, '%Y-%m-%d' )
    rescue Exception
      raise LSM_Error::InvalidDate
    end
  end #}}}

  # Read an entry from a file
  def from_file file #{{{
    found_begin = false
    # Search for beginning of entry {{{
    file.each do |line|
      if line[/^Begin4/]
        found_begin = true
        break
      end
    end #}}}

    raise LSM_Error::NoEntry, "No entry found" unless found_begin

    # Read entry into an Array {{{
    @lines = []
    file.each do |line|
      case line
      when /^End\s*$/
        completed = true
        break
      else
        lines << line
      end
    end #}}}

    line_num = -1
    while lines[line_num]
      line_num += 1
      current_line = line_num
      case lines[line_num]
      when /^([^:]+):\s*(.*)/im # Line containing a header {{{
        field, content = $1, $2

        # Check for whitespace before the colon {{{
        if field[/\s$/]
          @errors[current_line] = [
            "No whitespace allowed between keyword and colon (sorry)" ]
          next
        end #}}}

        # Merge any continuation lines {{{
        while lines[line_num+1] and lines[line_num+1][/^(\s+(.*)|$)/m]
          content << $1
          line_num+=1
        end #}}}

        # Store field data, if it's a known field {{{
        meth = field.downcase.gsub( /-/, '_' )
        if FIELDS.include? meth
          content = content.chomp.strip
          begin
            send "#{meth}=", content
          rescue LSM_Error
            @errors[current_line] = $!.explanation( field, content )
          end
        else
          @errors[current_line] = [ "Unknown keyword: #{field}" ]
        end #}}}
        #}}}
      when /^\s*$/ # Ignore empty lines before first field
      when nil; break
      else # Illegal line
        @errors[current_line] = [ "No keyword found",
          "  (lines beginning in column 1 must begin with a keyword)" ]
      end
    end

    self
  end #}}}

  # Convert attribute method name to field name
  def field_name meth #{{{
    meth.gsub(/_/, '-').sub(/^([a-z])/){ $1.upcase }
  end #}}}

  # Return a String containing the entry formatted for writing to a file
  def format #{{{
    header_length = FIELDS.map{|x| x.length}.max

    output = "Begin4\n"
    FIELDS.each do |meth|
      content = send meth
      next unless content
      field = field_name meth
      spaces = ' ' * (header_length - field.length)
      output << "#{field}: #{spaces}#{content}\n"
    end
    output << "End\n"
    output
  end #}}}

  # Report any errors found for the entry, returns a String or nil
  def report_errors #{{{
    return unless has_errors?
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
      field = field_name field
      output << "error: Required header '#{field}' is missing\n"
    end

    output
  end #}}}
end #}}}

if $0 == __FILE__ #{{{
  require 'yaml'
  entry = LSM_Entry.new.from_file( $< )
  status = if output = entry.report_errors
    1
  else
    output = entry.format
    0
  end
  puts output
  exit status
end #}}}

# vim: fdm=marker
