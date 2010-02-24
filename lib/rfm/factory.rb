# The classes in this module are used internally by RFM and are not intended for outside
# use.
#
# Author::    Geoff Coffey  (mailto:gwcoffey@gmail.com)
# Copyright:: Copyright (c) 2007 Six Fried Rice, LLC and Mufaddal Khumri
# License::   See MIT-LICENSE for details

module Rfm
  module Factory # :nodoc: all
    class DbFactory < Utility::CaseInsensitiveHash
    
      def initialize(server)
        @server = server
      end
      
      def [](dbname)
        super or (self[dbname] = Database.new(dbname, @server))
      end
      
      def all
        Result::ResultSet.new(@server, @server.do_action(@server.options[:account_name], @server.options[:password], '-dbnames', {}).body).each do |record|
          name = record['database_name']
          self[name] = Database.new(name, @server) if self[name] == nil
        end
        self.values
      end
    
    end
    
    class LayoutFactory < Utility::CaseInsensitiveHash
    
      def initialize(server, database)
        @server = server
        @database = database
      end
      
      def [](layout_name)
        super or (self[layout_name] = Layout.new(layout_name, @database))
      end
      
      def all
        Result::ResultSet.new(@server, @server.do_action(@server.options[:account_name], @server.options[:password], '-layoutnames', {"-db" => @database.name}).body).each do |record|
          name = record['layout_name']
          self[name] = Layout.new(name, @database) if self[name] == nil
        end
        self.values
      end
    
    end
    
    class ScriptFactory < Utility::CaseInsensitiveHash
    
      def initialize(server, database)
        @server = server
        @database = database
      end
      
      def [](script_name)
        super or (self[script_name] = Script.new(script_name, @database))
      end
      
      def all
        Result::ResultSet.new(@server, @server.do_action(@server.options[:account_name], @server.options[:password], '-scriptnames', {"-db" => @database.name}).body).each do |record|
          name = record['script_name']
          self[name] = Script.new(name, @database) if self[name] == nil
        end
        self.values
      end
    
    end
  end
end