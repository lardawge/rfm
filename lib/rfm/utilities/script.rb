# Script object exists so you can enumerate all scripts in a Database (which is a rare need):
# 
#   my_database.scripts.each {|script| puts script.name }
class Script #nodoc: all
  attr_accessor :name, :db
  def initialize(name, db)
    self.name = name
    self.db = db
  end
end