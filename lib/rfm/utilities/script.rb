# Script object exists so you can enumerate all scripts in a Database:
# 
#   my_database.scripts.each { |script| puts script.name }
module Rfm
  class Script #:nodoc: all
    attr_accessor :name, :db
    def initialize(name, db)
      self.name = name
      self.db = db
    end
  end 
end
