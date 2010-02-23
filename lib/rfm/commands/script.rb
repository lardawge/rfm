module Rfm
  # The Script object represents a FileMaker script. At this point, the Script object exists only so
  # you can enumrate all scripts in a Database (which is a rare need):
  # 
  #   my_database.scripts.each {|script| puts script.name }
  #
  # If you want to _run_ a script, see the Layout object instead.
  class Script #nodoc: all
    attr_accessor :name, :db
    def initialize(name, db)
      self.name = name
      self.db = db
    end
  end
end