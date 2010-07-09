require 'rubygems'
require 'bundler/setup'
require 'logger'
require 'rfm'

RSpec.configure do |c|
  c.mock_with :mocha
end

def rescue_from(&block)
  exception = nil
  begin
    yield
  rescue StandardError => e
    exception = e
  end
  exception
end
