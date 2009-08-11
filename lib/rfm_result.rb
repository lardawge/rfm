# This module includes classes that represent FileMaker data. When you communicate with FileMaker
# using, ie, the Layout object, you typically get back ResultSet objects. These contain Records,
# which in turn contain Fields, Portals, and arrays of data.
#
# Author::    Geoff Coffey  (mailto:gwcoffey@gmail.com)
# Copyright:: Copyright (c) 2007 Six Fried Rice, LLC and Mufaddal Khumri
# License::   See MIT-LICENSE for details
require 'bigdecimal'
require 'date'

module Rfm::Result
  
  # The ResultSet object represents a set of records in FileMaker. It is, in every way, a real Ruby
  # Array, so everything you expect to be able to do with an Array can be done with a ResultSet as well.
  # In this case, the elements in the array are Record objects.
  #
  # Here's a typical example, displaying the results of a Find:
  #
  #   myServer = Rfm::Server.new(...)
  #   results = myServer["Customers"]["Details"].find("First Name" => "Bill")
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
    
    # Initializes a new ResultSet object. You will probably never do this your self (instead, use the Layout
    # object to get various ResultSet obejects).
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
    def initialize(server, fmresultset, layout = nil)
      @server = server
      @resultset = nil
      @layout = layout
      @fields = Rfm::Util::CaseInsensitiveHash.new
      @portals = Rfm::Util::CaseInsensitiveHash.new
      @date_format = nil
      @time_format = nil
      @timestamp_format = nil
      @total_count = nil
      @foundset_count = nil
      
      doc = Nokogiri.XML(fmresultset)
      
      # check for errors
      error = doc.search('error').attr('code').to_i
      if error != 0 && (error != 401 || @server.state[:raise_on_401])
        raise Rfm::Error::FileMakerError.getError(error) 
      end
      
      # ascertain date and time formats
      datasource = doc.search('datasource')
      @date_format = convertFormatString(datasource.attr('date-format'))
      @time_format = convertFormatString(datasource.attr('time-format'))
      @timestamp_format = convertFormatString(datasource.attr('timestamp-format'))
      
      # process count metadata
      @total_count = datasource.attr('total-count').to_i
      @foundset_count = doc.search('resultset').attr('count').to_i
      
      # process field metadata
      doc.search('field-definition').each do |field|
        name = field['name']
        @fields[name] = Field.new(self, field)
      end
      @fields.freeze
      
      # process relatedset metadata
      doc.search('relatedset-definition').each do |relatedset|
        table = relatedset.attr('table')
        fields = {}
        relatedset.search('field-definition').each do |field|
          name = field.attr('name').sub(Regexp.new(table + '::'), '')
          fields[name] = Field.new(self, field)
        end
        @portals[table] = fields
      end
      @portals.freeze
      
      # build rows
      doc.search('record').each do |record|
        self << Record.new(record, self, @fields, @layout)
      end
    end  
        
    attr_reader :server, :fields, :portals, :date_format, :time_format, :timestamp_format, :total_count, :foundset_count, :layout
    
    private
    
    def convertFormatString(fm_format)
      fm_format.gsub('MM', '%m').gsub('dd', '%d').gsub('yyyy', '%Y').gsub('HH', '%H').gsub('mm', '%M').gsub('ss', '%S')
    end
    
  end
  
  # The Record object represents a single FileMaker record. You typically get them from ResultSet objects.
  # For example, you might use a Layout object to find some records:
  #
  #   results = myLayout.find({"First Name" => "Bill"})
  #
  # The +results+ variable in this example now contains a ResultSet object. ResultSets are really just arrays of
  # Record objects (with a little extra added in). So you can get a record object just like you would access any 
  # typical array element:
  #
  #   first_record = results[0]
  #
  # You can find out how many record were returned:
  #
  #   record_count = results.size
  #
  # And you can of course iterate:
  # 
  #   results.each (|record|
  #     // you can work with the record here
  #   )
  #
  # =Accessing Field Data
  #
  # You can access field data in the Record object in two ways. Typically, you simply treat Record like a hash
  # (because it _is_ a hash...I love OOP). Keys are field names:
  # 
  #   first = myRecord["First Name"]
  #   last = myRecord["Last Name"]
  #
  # If your field naming conventions mean that your field names are also valid Ruby symbol named (ie: they contain only
  # letters, numbers, and underscores) then you can treat them like attributes of the record. For example, if your fields
  # are called "first_name" and "last_name" you can do this:
  #
  #   first = myRecord.first_name
  #   last = myRecord.last_name
  #
  # Note: This shortcut will fail (in a rather mysterious way) if your field name happens to match any real attribute
  # name of a Record object. For instance, you may have a field called "server". If you try this:
  # 
  #   server_name = myRecord.server
  # 
  # you'll actually set +server_name+ to the Rfm::Server object this Record came from. This won't fail until you try
  # to treat it as a String somewhere else in your code. It is also possible a future version of Rfm will include
  # new attributes on the Record class which may clash with your field names. This will cause perfectly valid code
  # today to fail later when you upgrade. If you can't stomach this kind of insanity, stick with the hash-like
  # method of field access, which has none of these limitations. Also note that the +myRecord[]+ method is probably
  # somewhat faster since it doesn't go through +method_missing+.
  #
  # =Accessing Repeating Fields
  #
  # If you have a repeating field, RFM simply returns an array:
  #
  #   val1 = myRecord["Price"][0]
  #   val2 = myRecord["Price"][1]
  #
  # In the above example, the Price field is a repeating field. The code puts the first repetition in a variable called 
  # +val1+ and the second in a variable called +val2+.
  #
  # =Accessing Portals
  #
  # If the ResultSet includes portals (because the layout it comes from has portals on it) you can access them
  # using the Record::portals attribute. It is a hash with table occurrence names for keys, and arrays of Record
  # objects for values. In other words, you can do this:
  #
  #   myRecord.portals["Orders"].each {|record|
  #     puts record["Order Number"]
  #   }
  #
  # This code iterates through the rows of the _Orders_ portal.
  # 
  # =Field Types and Ruby Types
  #
  # RFM automatically converts data from FileMaker into a Ruby object with the most reasonable type possible. The 
  # type are mapped thusly:
  #
  # * *Text* fields are converted to Ruby String objects
  # 
  # * *Number* fields are converted to Ruby BigDecimal objects (the basic Ruby numeric types have
  #   much less precision and range than FileMaker number fields)
  #
  # * *Date* fields are converted to Ruby Date objects
  #
  # * *Time* fields are converted to Ruby DateTime objects (you can ignore the date component)
  #
  # * *Timestamp* fields are converted to Ruby DateTime objects
  #
  # * *Container* fields are converted to Ruby URI objects
  #
  # =Attributes
  #
  # In addition to +portals+, the Record object has these useful attributes:
  #
  # * *record_id* is FileMaker's internal identifier for this record (_not_ any ID field you might have
  #   in your table); you need a +record_id+ to edit or delete a record
  #
  # * *mod_id* is the modification identifier for the record; whenever a record is modified, its +mod_id+
  #   changes so you can tell if the Record object you're looking at is up-to-date as compared to another
  #   copy of the same record
  class Record < Rfm::Util::CaseInsensitiveHash
    
    # Initializes a Record object. You really really never need to do this yourself. Instead, get your records
    # from a ResultSet object.
    def initialize(row_element, resultset, fields, layout, portal=nil)
      @record_id = row_element['record-id']
      @mod_id = row_element['mod-id']
      @mods = {}
      @resultset = resultset
      @layout = layout
      
      @loaded = false
      
      row_element.search('field').each do |field| 
        field_name = field['name']
        field_name.sub!(Regexp.new(portal + '::'), '') if portal
        datum = []
        field.search('data').each do |x| 
          datum.push(fields[field_name].coerce(x.inner_text))
        end
        if datum.length == 1
          self[field_name] = datum[0]
        elsif datum.length == 0
          self[field_name] = nil
        else
          self[field_name] = datum
        end
      end
      
      @portals = Rfm::Util::CaseInsensitiveHash.new
      row_element.search('relatedset').each do |relatedset|
        table = relatedset['table']
        records = []
        relatedset.search('record').each do |record|
          records << Record.new(record, @resultset, @resultset.portals[table], @layout, table)
        end
        @portals[table] = records
      end      
      @loaded = true
    end
    
    attr_reader :record_id, :mod_id, :portals

    # Saves local changes to the Record object back to Filemaker. For example:
    #
    #   myLayout.find({"First Name" => "Bill"}).each(|record|
    #     record["First Name"] = "Steve"
    #     record.save
    #   )
    #
    # This code finds every record with _Bill_ in the First Name field, then changes the first name to 
    # Steve.
    #
    # Note: This method is smart enough to not bother saving if nothing has changed. So there's no need
    # to optimize on your end. Just save, and if you've changed the record it will be saved. If not, no
    # server hit is incurred.
    def save
      self.merge(@layout.edit(self.record_id, @mods)[0]) if @mods.size > 0
      @mods.clear
    end

    # Like Record::save, except it fails (and raises an error) if the underlying record in FileMaker was
    # modified after the record was fetched but before it was saved. In other words, prevents you from
    # accidentally overwriting changes someone else made to the record.
    def save_if_not_modified
      self.merge(@layout.edit(@record_id, @mods, {:modification_id => @mod_id})[0]) if @mods.size > 0
      @mods.clear
    end
    
    # Gets the value of a field from the record. For example:
    #
    #   first = myRecord["First Name"]
    #   last = myRecord["Last Name"]
    #
    # This sample puts the first and last name from the record into Ruby variables.
    #
    # You can also update a field:
    #
    #   myRecord["First Name"] = "Sophia"
    #
    # When you do, the change is noted, but *the data is not updated in FileMaker*. You must call
    # Record::save or Record::save_if_not_modified to actually save the data.
    def []=(pname, value)
      return super if !@loaded # this just keeps us from getting mods during initialization
      name = pname
      if self[name] != nil
        @mods[name] = val
      else
        raise Rfm::Error::ParameterError.new("You attempted to modify a field called '#{name}' on the Rfm::Record object, but that field does not exist.")
      end
    end
    
    def method_missing (symbol, *attrs)
      # check for simple getter
      return self[symbol.to_s] if self.include?(symbol.to_s) 

      # check for setter
      symbol_name = symbol.to_s
      if symbol_name[-1..-1] == '=' && self.has_key?(symbol_name[0..-2])
        return @mods[symbol_name[0..-2]] = attrs[0]
      end
      super
    end
    
    def respond_to?(symbol, include_private = false)
      return true if self[symbol.to_s] != nil
      super
    end
  end
  
  # The Field object represents a single FileMaker field. It *does not hold the data* in the field. Instead,
  # it serves as a source of metadata about the field. For example, if you're script is trying to be highly
  # dynamic about its field access, it may need to determine the data type of a field at run time. Here's
  # how:
  #
  #   field_name = "Some Field Name"
  #   case myRecord.fields[field_name].result
  #   when "text"
  #     # it is a text field, so handle appropriately
  #   when "number"
  #     # it is a number field, so handle appropriately
  #   end
  #
  # =Attributes
  #
  # The Field object has the following attributes useful attributes:
  #
  # * *name* is the name of the field
  #
  # * *result* is the data type of the field; possible values include:
  #   * text
  #   * number
  #   * date
  #   * time
  #   * timestamp
  #   * container
  #
  # * *type* any of these:
  #   * normal (a normal data field)
  #   * calculation
  #   * summary
  #
  # * *max_repeats* is the number of repetitions (1 for a normal field, more for a repeating field)
  #
  # * *global* is +true+ is this is a global field, *false* otherwise
  #
  # Note: Field types match FileMaker's own values, but the terminology differs. The +result+ attribute
  # tells you the data type of the field, regardless of whether it is a calculation, summary, or normal
  # field. So a calculation field whose result type is _timestamp_ would have these attributes:
  #
  # * result: timestamp
  # * type: calculation
  #
  # * *control& is a FieldControl object representing the sytle and value list information associated
  #   with this field on the layout.
  # 
  # Note: Since a field can sometimes appear on a layout more than once, +control+ may be an Array.
  # If you don't know ahead of time, you'll need to deal with this. One easy way is:
  #
  #   controls = [myField.control].flatten
  #   controls.each {|control|
  #     # do something with the control here
  #   }
  #
  # The code above makes sure the control is always an array. Typically, though, you'll know up front
  # if the control is an array or not, and you can code accordingly.
  
  class Field
    
    # Initializes a field object. You'll never need to do this. Instead, get your Field objects from
    # ResultSet::fields
    def initialize(result_set, field)
      @result_set = result_set
      @name = field['name']
      @result = field['result']
      @type = field['type']
      @max_repeats = field['max-repeats']
      @global = field['global']
      
      @loaded = false
    end
    
    attr_reader :name, :result, :type, :max_repeats, :global

    def control
      @result_set.layout.field_controls[@name]
    end

    # Coerces the text value from an +fmresultset+ document into proper Ruby types based on the 
    # type of the field. You'll never need to do this: Rfm does it automatically for you when you
    # access field data through the Record object.
    def coerce(value)
      return nil if (value == nil || value == '') && @result != "text"
      case @result
      when "text"
        return value
      when "number"
        return BigDecimal.new(value)
      when "date"
        return Date.strptime(value, @result_set.date_format)
      when "time"
        return DateTime.strptime("1/1/-4712 " + value, "%m/%d/%Y #{@result_set.time_format}")
      when "timestamp"
        return DateTime.strptime(value, @result_set.timestamp_format)
      when "container"
        return URI.parse("#{@result_set.server.scheme}://#{@result_set.server.host_name}:#{@result_set.server.port}#{value}")
      else
        return nil
      end
    end
  end
  
end