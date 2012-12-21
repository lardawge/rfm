# encoding: utf-8
require 'rfm/utilities/case_insensitive_hash'
require 'rfm/utilities/factory'
require 'rfm/error'
require 'rfm/server'
require 'rfm/database'
require 'rfm/layout'
require 'rfm/resultset'

module Rfm
  
  class CommunicationError  < StandardError; end
  class ParameterError      < StandardError; end
  class AuthenticationError < StandardError; end

end
