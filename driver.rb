$LOAD_PATH << '.'
require 'spec'
require 'scanner'
require 'parser'
require 'error_report'

# load the source
source = File.open(ARGV.first, 'r') {|f| f.read}

# initialize the error report
error_report = ErrorReport.new source

# initialize the scanner
scanner = Scanner.new(source, Spec::REG_EXPS, error_report)

# parse
parser = Parser.new(scanner, error_report).parse
