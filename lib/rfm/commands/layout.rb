module Rfm
  # The Layout object represents a single FileMaker Pro layout. You use it to interact with 
  # records in FileMaker. *All* access to FileMaker data is done through a layout, and this
  # layout determines which _table_ you actually hit (since every layout is explicitly associated
  # with a particular table -- see FileMakers Layout->Layout Setup dialog box). You never specify
  # _table_ information directly in RFM.
  #
  # Also, the layout determines which _fields_ will be returned. If a layout contains only three
  # fields from a large table, only those three fields are returned. If a layout includes related
  # fields from another table, they are returned as well. And if the layout includes portals, all
  # data in the portals is returned (see Record::portal for details).
  #
  # As such, you can _significantly_ improve performance by limiting what you put on the layout.
  #
  # =Using Layouts
  #
  # The Layout object is where you get most of your work done. It includes methods for all
  # FileMaker actions:
  # 
  # * Layout::all
  # * Layout::any
  # * Layout::find
  # * Layout::edit
  # * Layout::create
  # * Layout::delete
  #
  # =Running Scripts
  # 
  # In FileMaker, execution of a script must accompany another action. For example, to run a script
  # called _Remove Duplicates_ with a found set that includes everybody
  # named _Bill_, do this:
  #
  #   myLayout.find({"First Name" => "Bill"}, :post_script => "Remove Duplicates")
  #
  # ==Controlling When the Script Runs
  #
  # When you perform an action in FileMaker, it always executes in this order:
  # 
  # 1. Perform any find
  # 2. Sort the records
  # 3. Return the results
  #
  # You can control when in the process the script runs. Each of these options is available:
  #
  # * *post_script* tells FileMaker to run the script after finding and sorting
  # * *pre_find_script* tells FileMaker to run the script _before_ finding
  # * *pre_sort_script* tells FileMaker to run the script _before_ sorting, but _after_ finding
  #
  # ==Passing Parameters to a Script
  # 
  # If you want to pass a parameter to the script, use the options above, but supply an array value
  # instead of a single string. For example:
  #
  #   myLayout.find({"First Name" => "Bill"}, :post_script => ["Remove Duplicates", 10])
  #
  # This sample runs the script called "Remove Duplicates" and passes it the value +10+ as its 
  # script parameter.
  #
  # =Common Options
  # 
  # Most of the methods on the Layout object accept an optional hash of +options+ to manipulate the
  # action. For example, when you perform a find, you will typiclaly get back _all_ matching records. 
  # If you want to limit the number of records returned, you can do this:
  #
  #   myLayout.find({"First Name" => "Bill"}, :max_records => 100)
  # 
  # The +:max_records+ option tells FileMaker to limit the number of records returned.
  #
  # This is the complete list of available options:
  # 
  # * *max_records* tells FileMaker how many records to return
  #
  # * *skip_records* tells FileMaker how many records in the found set to skip, before
  #   returning results; this is typically combined with +max_records+ to "page" through 
  #   records
  #
  # * *sort_field* tells FileMaker to sort the records by the specified field
  # 
  # * *sort_order* can be +descend+ or +ascend+ and determines the order
  #   of the sort when +sort_field+ is specified
  #
  # * *post_script* tells FileMaker to perform a script after carrying out the action; you 
  #   can pass the script name, or a two-element array, with the script name first, then the
  #   script parameter
  #
  # * *pre_find_script* is like +post_script+ except the script runs before any find is 
  #   performed
  #
  # * *pre_sort_script* is like +pre_find_script+ except the script runs after any find
  #   and before any sort
  # 
  # * *response_layout* tells FileMaker to switch layouts before producing the response; this
  #   is useful when you need a field on a layout to perform a find, edit, or create, but you
  #   want to improve performance by not including the field in the result
  #
  # * *logical_operator* can be +and+ or +or+ and tells FileMaker how to process multiple fields
  #   in a find request
  # 
  # * *modification_id* lets you pass in the modification id from a Record object with the request;
  #   when you do, the action will fail if the record was modified in FileMaker after it was retrieved
  #   by RFM but before the action was run
  #
  #
  # =Attributes
  #
  # The Layout object has a few useful attributes:
  #
  # * +name+ is the name of the layout
  #
  # * +field_controls+ is a hash of FieldControl objects, with the field names as keys. FieldControl's
  #   tell you about the field on the layout: how is it formatted and what value list is assigned
  #
  # Note: It is possible to put the same field on a layout more than once. When this is the case, the
  # value in +field_controls+ for that field is an array with one element representing each instance
  # of the field.
  # 
  # * +value_lists+ is a hash of arrays. The keys are value list names, and the values in the hash
  #   are arrays containing the actual value list items. +value_lists+ will include every value
  #   list that is attached to any field on the layout
  
  class Layout
    
    # Initialize a layout object. You never really need to do this. Instead, just do this:
    # 
    #   my_server = Rfm::Server.new(...)
    #   my_db = my_server["Customers"]
    #   my_layout = my_db["Details"]
    #
    # This sample code gets a layout object representing the Details layout in the Customers database
    # on the FileMaker server.
    # 
    # In case it isn't obvious, this is more easily expressed this way:
    #
    #   my_server = Rfm::Server.new(...)
    #   my_layout = my_server("Customers")["Details"]
    def initialize(name, db)
      @name = name
      @db = db
    end
    
    attr_reader :name, :db
    
    def field_controls
      load_layout_data unless defined? @field_controls
      @field_controls
    end
    
    def value_lists
      load_layout_data unless defined? @value_lists
      @value_lists
    end
    
    # Returns a ResultSet object containing _every record_ in the table associated with this layout.
    def all(options={})
      get_records('-findall', {}, options)
    end
    
    # Returns a ResultSet containing a single random record from the table associated with this layout.
    def any(options={})
      get_records('-findany', {}, options)
    end
  
    # Finds a record. Typically you will pass in a hash of field names and values. For example:
    #
    #   myLayout.find({"First Name" => "Bill"})
    #
    # Values in the hash work just like value in FileMaker's Find mode. You can use any special
    # symbols (+==+, +...+, +>+, etc...).
    #
    # If you pass anything other than a hash as the first parameter, it is converted to a string and
    # assumed to be FileMaker's internal id for a record (the recid).
    def find(hash_or_recid, options={})
      if hash_or_recid.kind_of? Hash
        get_records('-find', hash_or_recid, options)
      else
        get_records('-find', {'-recid' => hash_or_recid.to_s}, options)
      end
    end
  
    # Updates the contents of the record whose internal +recid+ is specified. Send in a hash of new
    # data in the +values+ parameter. Returns a RecordSet containing the modified record. For example:
    #
    #   recid = myLayout.find({"First Name" => "Bill"})[0].record_id
    #   myLayout.edit(recid, {"First Name" => "Steve"})
    #
    # The above code would find the first record with _Bill_ in the First Name field and change the 
    # first name to _Steve_.
    def edit(recid, values, options = {})
      get_records('-edit', {'-recid' => recid}.merge(values), options)
    end
    
    # Creates a new record in the table associated with this layout. Pass field data as a hash in the 
    # +values+ parameter. Returns the newly created record in a RecordSet. You can use the returned
    # record to, ie, discover the values in auto-enter fields (like serial numbers). 
    #
    # For example:
    #
    #   result = myLayout.create({"First Name" => "Jerry", "Last Name" => "Robin"})
    #   id = result[0]["ID"]
    #
    # The above code adds a new record with first name _Jerry_ and last name _Robin_. It then
    # puts the value from the ID field (a serial number) into a ruby variable called +id+.
    def create(values, options = {})
      get_records('-new', values, options)
    end
    
    # Deletes the record with the specified internal recid. Returns a ResultSet with the deleted record.
    #
    # For example:
    #
    #   recid = myLayout.find({"First Name" => "Bill"})[0].record_id
    #   myLayout.delete(recid)
    # 
    # The above code finds every record with _Bill_ in the First Name field, then deletes the first one.
    def delete(recid, options = {})
      get_records('-delete', {'-recid' => recid}, options)
      return nil
    end
    
    private
    
      def load_layout_data
        doc = Nokogiri.XML(@db.server.load_layout(self).body)

        # check for errors
        error = doc.search('ERRORCODE').text.to_i
        raise Rfm::Error::FileMakerError.get_error(error) if error != 0
        
        value_lists = doc.search('VALUELISTS')
        layouts = doc.search('LAYOUT')
        
        # process valuelists
        @value_lists = Rfm::Utility::CaseInsensitiveHash.new
        unless value_lists.empty?
          value_lists.search('VALUELIST').each do |valuelist|
            name = valuelist.attribute('NAME').value
            @value_lists[name] = valuelist.children.collect { |e| e.text }
          end
        end
        
        # process field controls
        @field_controls = Rfm::Utility::CaseInsensitiveHash.new
        layouts.search('FIELD').each do |field| 
          name = field.attribute('NAME').value
          style = field.search('STYLE')
          type = style.attribute('TYPE').value
          value_list_name = style.attribute('VALUELIST').value
          value_list = @value_lists[value_list_name] if value_list_name != ''
          field_control = FieldControl.new(name, type, value_list_name, value_list)
          existing = @field_controls[name]
          if existing
            if existing.kind_of?(Array)
              existing << field_control
            else
              @field_controls[name] = Array[existing, field_control]
            end
          else
            @field_controls[name] = field_control
          end
        end     
      end
      
      def get_records(action, extra_params = {}, options = {})
        Rfm::Result::ResultSet.new(@db.server, @db.server.do_action(@db.account_name, 
        @db.password, action, params().merge(extra_params), options).body, self)
      end
      
      def params
        {"-db" => @db.name, "-lay" => self.name}
      end
  end
end