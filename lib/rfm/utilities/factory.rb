# The classes in this module are used internally by RFM and are not intended for outside
# use.
#
# Author::    Geoff Coffey  (mailto:gwcoffey@gmail.com)
# Copyright:: Copyright (c) 2007 Six Fried Rice, LLC and Mufaddal Khumri
# License::   See MIT-LICENSE for details

module Rfm
  module Factory # :nodoc: all
    class DbFactory < Rfm::CaseInsensitiveHash
    
      def initialize(server)
        @server = server
        @loaded = false
      end
      
      def [](dbname)
        super or (self[dbname] = Rfm::Database.new(dbname, @server))
      end
      
      def all
        if !@loaded
          Rfm::Result::ResultSet.new(@server, @server.do_action(@server.state[:account_name], @server.state[:password], '-dbnames', {}).body).each {|record|
            name = record['DATABASE_NAME']
            self[name] = Rfm::Database.new(name, @server) if self[name] == nil
          }
          @loaded = true
        end
        self.values
      end
    
    end
    
    class LayoutFactory < Rfm::CaseInsensitiveHash
    
      def initialize(server, database)
        @server = server
        @database = database
        @loaded = false
      end
      
      def [](layout_name)
        super or (self[layout_name] = Rfm::Layout.new(layout_name, @database))
      end
      
      def all
        if !@loaded
          Rfm::Result::ResultSet.new(@server, @server.do_action(@server.state[:account_name], @server.state[:password], '-layoutnames', {"-db" => @database.name}).body).each {|record|
            name = record['LAYOUT_NAME']
            self[name] = Rfm::Layout.new(name, @database) if self[name] == nil
          }
          @loaded = true
        end
        self.values
      end
    
    end
    
    class ScriptFactory < Rfm::CaseInsensitiveHash
    
      def initialize(server, database)
        @server = server
        @database = database
        @loaded = false
      end
      
      def [](script_name)
        super or (self[script_name] = Rfm::Script.new(script_name, @database))
      end
      
      def all
        if !@loaded
          Rfm::Result::ResultSet.new(@server, @server.do_action(@server.state[:account_name], @server.state[:password], '-scriptnames', {"-db" => @database.name}).body).each {|record|
            name = record['SCRIPT_NAME']
            self[name] = Rfm::Script.new(name, @database) if self[name] == nil
          }
          @loaded = true
        end
        self.values
      end
    
    end
  end
end