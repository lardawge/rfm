require 'bigdecimal'
require 'date'

module Rfm
  
  # The ResultSet object represents a set of records in FileMaker. It is, in every way, a real Ruby
  # Array, so everything you expect to be able to do with an Array can be done with a ResultSet as well.
  # In this case, the elements in the array are Record objects.
  #
  # Here's a typical example, displaying the results of a Find:
  #
  #   my_server = Rfm::Server.new(...)
  #   results = my_server.db("Customers").layout("Details").find("First Name" => "Bill")
  #   results.each {|record|
  #     puts record["First Name"]
  #     puts record["Last Name"]
  #     puts record["Email Address"]
  #   }
  #
  # =Attributes
  #
  # The ResultSet object has several useful attributes:
  #
  # * *server* is the server object this ResultSet came from
  #
  # * *fields* is a hash with field names for keys and Field objects for values; it provides 
  #   metadata about the fields in the ResultSet
  #
  # * *portals* is a hash with table occurrence names for keys and arrays of Field objects for values;
  #   it provides metadata about the portals in the ResultSet and the Fields on those portals

  class ResultSet < Array
    attr_reader :server, :fields, :portals, :date_format, :time_format, :timestamp_format, :total_count, :foundset_count, :layout
    
    # Initializes a new ResultSet object. You will probably never do this your self (instead, use the Layout
    # object to get various ResultSet objects).
    #
    # If you feel so inclined, though, pass a Server object, and some +fmpxmlresult+ compliant XML in a String.
    #
    # =Attributes
    #
    # The ResultSet object includes several useful attributes:
    #
    # * *fields* is a hash (with field names for keys and Field objects for values). It includes an entry for
    #   every field in the ResultSet. Note: You don't use Field objects to access _data_. If you're after 
    #   data, get a Record object (ResultSet is an array of records). Field objects tell you about the fields
    #   (their type, repetitions, and so forth) in case you find that information useful programmatically.
    #
    #   Note: keys in the +fields+ hash are downcased for convenience (and [] automatically downcases on 
    #   lookup, so it should be seamless). But if you +each+ a field hash and need to know a field's real
    #   name, with correct case, do +myField.name+ instead of relying on the key in the hash.
    #
    # * *portals* is a hash (with table occurrence names for keys and Field objects for values). If your
    #   layout contains portals, you can find out what fields they contain here. Again, if it's the data you're
    #   after, you want to look at the Record object.
    
    def initialize(server, fm_data, layout=nil)
      @server = server
      @layout = layout
      @fields = CaseInsensitiveHash.new
      @portals = CaseInsensitiveHash.new
      @date_format = nil
      @time_format = nil
      @timestamp_format = nil
      @total_count = nil
      @foundset_count = nil
      
      doc = Nokogiri.XML(fm_data)
      
      check_for_errors(doc.css('error').attribute('code').value.to_i)
      
      # seperate content sections
      metadata = doc.css('metadata')
      source   = doc.css('datasource')
      result   = doc.css('resultset')
      
      # ascertain date and time formats
      @date_format      = convert_format_string(source.attribute('date-format').value)
      @time_format      = convert_format_string(source.attribute('time-format').value)
      @timestamp_format = convert_format_string(source.attribute('timestamp-format').value)
      
      # retrieve count
      @foundset_count = result.attribute('count').value.to_i
      @total_count    = source.attribute('total-count').value.to_i
      
      # process field metadata
      metadata.css('field-definition').each do |field|
        @fields[field['name']] = Field.new(self, field)
      end
      
      # process relatedset metadata
      metadata.css('relatedset-definition').each do |relatedset|
        table  = relatedset.attribute('table').value
        fields = Hash.new
        relatedset.css('field-definition').each do |field|
          name = field.attribute('name').value.sub(Regexp.new(table + '::'), '')
          fields[name] = Field.new(self, field)
        end
        @portals[table] = fields
      end
      
      # build record rows
      result.css('record').each do |record|
        self << Record.new(record, self, @fields, @layout)
      end
    end  
    
    private
    
      def check_for_errors(error_code)
        raise FileMakerError.get(error_code) if error_code != 0 && (error_code != 401 || @server.options[:raise_on_401])
      end
    
      def convert_format_string(fm_format)
        fm_format.gsub('MM', '%m').gsub('dd', '%d').gsub('yyyy', '%Y').gsub('HH', '%H').gsub('mm', '%M').gsub('ss', '%S')
      end
    
  end
end