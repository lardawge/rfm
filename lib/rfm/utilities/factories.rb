autoload :Script, "rfm/utilities/script"
# The classes in this module are used internally by Rfm and are not intended for outside
# use.
#
# Author::    Geoff Coffey  (mailto:gwcoffey@gmail.com)
# Copyright:: Copyright (c) 2007 Six Fried Rice, LLC and Mufaddal Khumri
# License::   See MIT-LICENSE for details

module Factories
  class DbFactory < Rfm::CaseInsensitiveHash
  
    def initialize(server)
      @server = server
    end
    
    def [](dbname)
      super or (self[dbname] = Rfm::Database.new(dbname, @server))
    end
    
    def all
      Rfm::ResultSet.new(@server, @server.do_action(@server.options[:account_name], @server.options[:password], '-dbnames', {}).body).each do |record|
        name = record['database_name']
        self[name] = Rfm::Database.new(name, @server) if self[name] == nil
      end
      self.values
    end
  
  end
  
  class LayoutFactory < Rfm::CaseInsensitiveHash
  
    def initialize(server, database)
      @server = server
      @database = database
    end
    
    def [](layout_name)
      super or (self[layout_name] = Rfm::Layout.new(layout_name, @database))
    end
    
    def all
      Rfm::ResultSet.new(@server, @server.do_action(@server.options[:account_name], @server.options[:password], '-layoutnames', {"-db" => @database.name}).body).each do |record|
        name = record['layout_name']
        self[name] = Rfm::Layout.new(name, @database) if self[name] == nil
      end
      self.values
    end
  
  end
  
  class ScriptFactory < Rfm::CaseInsensitiveHash
    def initialize(server, database)
      @server = server
      @database = database
    end
    
    def [](script_name)
      super or (self[script_name] = Script.new(script_name, @database))
    end
    
    def all
      Rfm::ResultSet.new(@server, @server.do_action(@server.options[:account_name], @server.options[:password], '-scriptnames', {"-db" => @database.name}).body).each do |record|
        name = record['script_name']
        self[name] = Script.new(name, @database) if self[name] == nil
      end
      self.values
    end
  
  end
end