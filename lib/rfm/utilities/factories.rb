# The classes in this module are used internally by Rfm and are not intended for outside
# use.
module Rfm
  autoload :Script, "rfm/utilities/script"
  
  module Factories #:nodoc: all
    
    class Factory < CaseInsensitiveHash
      
      def initialize(server, database=nil)
        @server = server
        @database = database
      end
      
      def [](name)
        super or (self[name] = instantiate_klass(name))
      end
      
      def all
        set_options
        ResultSet.new(@server, @server.do_action(@server.options[:account_name], @server.options[:password], @url_options, @database.nil? ? {} : { '-db' => @database.name }).body).each do |record|
          name = record[@hash_key]
          self[name] = instantiate_klass(name) if self[name].nil?
        end
        self.values
      end
      
    end
    
    class DbFactory < Factory
      
      def set_options
        @hash_key = 'database_name'
        @url_options = '-dbnames'
      end
      
      def instantiate_klass(dbname)
        Database.new(dbname, @server)
      end
    
    end
    
    class LayoutFactory < Factory
      
      def set_options
        @hash_key = 'layout_name'
        @url_options = '-layoutnames'
      end
      
      def instantiate_klass(layout_name)
        Layout.new(layout_name, @database)
      end
    
    end
    
    class ScriptFactory < Factory
      
      def set_options
        @hash_key = 'script_name'
        @url_options = '-scriptnames'
      end
      
      def instantiate_klass(script_name)
        Script.new(script_name, @database)
      end
    
    end
  end
end