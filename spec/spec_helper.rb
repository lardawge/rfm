require 'rubygems'
require 'bundler/setup'
require 'logger'
require 'rfm'

RSpec.configure do |c|
  c.mock_with :mocha
end
