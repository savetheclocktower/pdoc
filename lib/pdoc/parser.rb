require 'rubygems'
require 'treetop'

FILE_NAMES = %w[basic tags argument_description description ebnf_arguments ebnf_expression section_content documentation]

FILE_NAMES.each { |file_name| require "#{file_name}_nodes" }

%w[ebnf_javascript events].concat(FILE_NAMES).each do |file_name|
  Treetop.load File.expand_path(File.join(PARSER_DIR, "treetop_files", file_name))
end

module PDoc
  class Parser
    def initialize(string)
      @string = string
      @parser = DocumentationParser.new
    end
    
    # Parses the preprocessed string. Returns an instance
    # of Documentation::Doc
    def parse
      result = @parser.parse(pre_process)
      raise ParseError, @parser unless result
      result
    end
    
    # Preprocess the string before parsing.
    # Converts "\r\n" to "\n" and avoids edge case
    # by wrapping the string in line breaks.
    def pre_process
      "\n" << @string.gsub(/\r\n/, "\n") << "\n"
    end
  end
  
  # Thrown by PDoc::Parser if the documentation is malformed.
  class ParseError < StandardError
    def initialize(parser)
      @parser = parser
      @lines = @parser.input.split("\n").unshift("")
    end
    
    def message
      <<-EOS
      
ParseError: Expected #{expected_string} at line #{line}, column #{column} (byte #{index + 1}) after #{@parser.input[@parser.index...index].inspect}.
      
#{source_code}
      
      EOS
    end
    
    def line
      @parser.failure_line
    end
    
    def column
      @parser.failure_column
    end
    
    def failures
      @parser.terminal_failures
    end
    
    def index
      @parser.failure_index
    end
    
    def source_code
      ((line-2)..(line+2)).map do |index|
        result = index == line ? "-->" : "   "
        "#{result} #{index.to_s.rjust(5)} #{@lines[index]}"
      end.join("\n")
    end
    
    def failure_reason
      ""
    end
    
    def expected_string
      if failures.size == 1
        failures.first.expected_string.inspect
      else
        expected = failures.map { |f| f.expected_string.inspect }.uniq
        last = expected.pop
        "one of #{expected.join(', ')} or #{last}"
      end
    end
  end
end
