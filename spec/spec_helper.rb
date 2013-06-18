require 'coveralls'
Coveralls.wear!

require 'rspec'
require 'stretcher'

File.open("test_logs", 'wb') {|f| f.write("")}
DEBUG_LOGGER = Logger.new('test_logs')
ES_URL = 'http://localhost:9200'
require File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib stretcher]))
