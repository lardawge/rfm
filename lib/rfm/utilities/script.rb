# Script object exists so you can enumerate all scripts in a Database:
# 
#   my_database.scripts.each { |script| puts script.name }
module Rfm
  class Script #:nodoc: all
    attr_reader :name
    def initialize(name)
      @name = name
    end
  end 
end
