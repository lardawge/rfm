module Rfm
  
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
  class Record < Rfm::CaseInsensitiveHash
    
    attr_reader :record_id, :mod_id, :portals

    def initialize(record, result, field_meta, layout, portal=nil)
      @record_id = record['record-id']
      @mod_id    = record['mod-id']
      @mods      = {}
      @layout    = layout
      @portals ||= Rfm::CaseInsensitiveHash.new

      relatedsets = !portal && result.instance_variable_get(:@include_portals) ? record.xpath('relatedset') : []
      
      record.xpath('field').each do |field|
        field_name = field['name']
        field_name.gsub!(Regexp.new(portal + '::'), '') if portal
        datum = []
        
        field.xpath('data').each do |x| 
          datum.push(field_meta[field_name].coerce(x.inner_text, result))
        end
      
        if datum.length == 1
          self[field_name] = datum[0]
        elsif datum.length == 0
          self[field_name] = nil
        else
          self[field_name] = datum
        end
      end
      
      unless relatedsets.empty?
        relatedsets.each do |relatedset|
          tablename, records = relatedset['table'], []
      
          relatedset.xpath('record').each do |record|
            records << self.class.new(record, result, result.portal_meta[tablename], layout, tablename)
          end
      
          @portals[tablename] = records
        end
      end
      
      @loaded = true
    end

    def self.build_records(records, result, field_meta, layout, portal=nil)
      records.each do |record|
        result << self.new(record, result, field_meta, layout, portal)
      end
    end

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
    def []=(name, value)
      return super unless @loaded
      raise Rfm::ParameterError, 
        "You attempted to modify the field :#{name} which does not exist in the current Filemaker layout." unless self.key?(name)
      @mods[name] = value
    end

    alias :_original_hash_reader :[]
    def [](value)
      read_attribute(value)
    end

    def respond_to?(symbol, include_private = false)
      return true if self.include?(symbol.to_s)
      super
    end

    private

      def read_attribute(key)
        raise NoMethodError, 
          "#{key} does not exists as a field in the current Filemaker layout." unless key?(key)
        _original_hash_reader(key)
      end

      def method_missing(symbol, *attrs, &block)
        method = symbol.to_s
        return read_attribute(method) if self.key?(method)
      
        if method =~ /(=)$/ && self.key?($`)
          return @mods[$`] = attrs.first
        end
        super
      end
    
  end
end
