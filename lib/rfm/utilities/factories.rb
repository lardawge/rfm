# The classes in this module are used internally by Rfm and are not intended for outside
# use.
module Rfm
  autoload :Script, "rfm/utilities/script"
  
  module Factories #:nodoc: all
    
    class Factory < CaseInsensitiveHash
      
      def [](name)
        super or (self[name] = instantiate_klass(name))
      end

      def all
        set_options
        params   = ParamsBuilder.parse(@action)
        response = Response.http(params)
        
        ResultSet.new(response).each do |record|
          name = record[@hash_key]
          self[name] = instantiate_klass(name) if self[name].nil?
        end
        self.values
      end
      
    end
    
    class DbFactory < Factory
      
      def set_options
        @hash_key = 'database_name'
        @action  = :dbnames
      end
      
      def instantiate_klass(dbname)
        Database.new(dbname)
      end
    
    end
    
    class LayoutFactory < Factory
      
      def set_options
        @hash_key = 'layout_name'
        @action  = :layoutnames
      end
      
      def instantiate_klass(layout_name)
        Layout.new(layout_name)
      end
    
    end
    
    class ScriptFactory < Factory
      
      def set_options
        @hash_key = 'script_name'
        @action  = :scriptnames
      end
      
      def instantiate_klass(script_name)
        Script.new(script_name)
      end
    
    end
  end
end