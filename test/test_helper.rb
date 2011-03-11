ENV['RACK_ENV'] = 'test'

require File.expand_path( "#{File.dirname(__FILE__)}/../app/thimbl_singing" )
require 'rack/test'
require 'test/unit'
require 'webrat'
require 'mocha'

FIXTURES_PATH = File.expand_path( "#{File.dirname(__FILE__)}/fixtures" )