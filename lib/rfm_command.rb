require 'net/http'
require 'rexml/document'
require 'cgi'

# This module includes classes that represent base FileMaker concepts like servers,
# layouts, and scripts. These classes allow you to communicate with FileMaker Server,
# send commands, and receive responses.
#
# Author::    Geoff Coffey  (mailto:gwcoffey@gmail.com)
# Copyright:: Copyright (c) 2007 Six Fried Rice, LLC and Mufaddal Khumri
# License::   See MIT-LICENSE for details
module Rfm

  # This class represents a single FileMaker server. It is initialized with basic
  # connection information, including the hostname, port number, and default database
  # account name and password.
  #
  # Note: The host and port number refer to the FileMaker Web Publishing Engine, which
  # must be installed and configured in order to use RFM. It may not actually be running
  # on the same server computer as FileMaker Server itself. See your FileMaker Server
  # or FileMaker Server Advanced documentation for information about configuring a Web
  # Publishing Engine.
  #
  # =Accessing Databases
  #
  # Typically, you access a Database object from the Server like this:
  #
  #   myDatabase = myServer["Customers"]
  # 
  # This code gets the Database object representing the Customers object.
  # 
  # Note: RFM does not talk to the server when you retrieve a database object in this way. Instead, it
  # simply assumes you know what you're talking about. If the database you specify does not exist, you 
  # will get no error at this point. Instead, you'll get an error when you use the Layout object you get
  # from this database. This makes debugging a little less convenient, but it would introduce too much
  # overhead to hit the server at this point.
  #
  # The Server object has a +db+ attribute that provides alternate access to Database objects. It acts
  # like a hash of Database objects, one for each accessible database on the server. So, for example, you
  # can do this if you want to print out a list of all databses on the server:
  # 
  #   myServer.db.each {|database|
  #     puts database.name
  #   }
  # 
  # The Server::db attribute is actually a DbFactory object, although it subclasses hash, so it should work
  # in all the ways you expect. Note, though, that it is completely empty until the first time you attempt 
  # to access its elements. At that (lazy) point, it hits FileMaker, loads in the list of databases, and
  # constructs a Database object for each one. In other words, it incurrs no overhead until you use it.
  #
  # =Attributes
  # 
  # In addition to the +db+ attribute, Server has a few other useful attributes:
  #
  # * *host_name* is the host name this server points to
  # * *post* is the port number this server communicates on
  # * *state* is a hash of all server options used to initialize this server
  
  class Server
    
    # To create a Server obejct, you typically need at least a host name:
    # 
    #   myServer = Rfm::Server.new({:host => 'my.host.com'})
    #
    # Several other options are supported:
    #
    # * *host* the hostname of the Web Publishing Engine (WPE) server (defaults to 'localhost')
    #
    # * *port* the port number the WPE is listening no (defaults to 80)
    #
    # * *ssl* +true+ if you want to use SSL (HTTPS) to connect to FileMaker (defaults to +false+)
    #
    # * *account_name* the default account name to log in to databases with (you can also supply a
    #   account name on a per-database basis if necessary)
    #
    # * *password* the default password to log in to databases with (you can also supplly a password
    #   on a per-databases basis if necessary)
    #
    # * *log_actions* when +true+, RFM logs all action URLs that are sent to FileMaker server to stderr
    #   (defaults to +false+)
    #
    # * *log_responses* when +true+, RFM logs all raw XML responses (including headers) from FileMaker to
    #   stderr (defaults to +false+)
    #
    # * *warn_on_redirect* normally, RFM prints a warning to stderr if the Web Publishing Engine redirects
    #   (this can usually be fixed by using a different host name, which speeds things up); if you *don't*
    #   want this warning printed, set +warn_on_redirect+ to +true+
    #
    # * *raise_on_401* although RFM raises error when FileMaker returns error responses, it typically
    #   ignores FileMaker's 401 error (no records found) and returns an empty record set instead; if you
    #   prefer a raised error when a find produces no errors, set this option to +true+
    def initialize(options)
      @state = {
        :host => 'localhost',
        :port => 80,
        :ssl => false,
        :account_name => '',
        :password => '',
        :log_actions => false,
        :log_responses => false,
        :warn_on_redirect => true,
        :raise_on_401 => false
      }.merge(options)
      
      if @state[:username] != nil
        warn("the :username option on Rfm::Server::initialize has been deprecated. Use :account_name instead.")
        @state[:account_name] = @state[:username]
      end
      
      @state.freeze
      
      @host_name = @state[:host]
      @scheme = @state[:ssl] ? "https" : "http"
      @port = @state[:port]
      
      @db = Rfm::Factory::DbFactory.new(self)
    end
    
    # Access the database object representing a database on the server. For example:
    #
    #   myServer['Customers']
    #
    # would return a Database object representing the _Customers_
    # database on the server.
    #
    # Note: RFM never talks to the server until you perform an action. The database object
    # returned is created on the fly and assumed to refer to a valid database, but you will
    # get no error at this point if the database you access doesn't exist. Instead, you'll
    # receive an error when you actually try to perform some action on a layout from this
    # database.
    def [](dbname)
      self.db[dbname]
    end

    attr_reader :db, :host_name, :port, :scheme, :state

    # Performs a raw FileMaker action. You will generally not call this method directly, but it
    # is exposed in case you need to do something "under the hood."
    # 
    # The +action+ parameter is any valid FileMaker web url action. For example, +-find+, +-finadny+ etc.
    #
    # The +args+ parameter is a hash of arguments to be included in the action url. It will be serialized
    # and url-encoded appropriately.
    #
    # The +options+ parameter is a hash of RFM-specific options, which correspond to the more esoteric
    # FileMaker URL parameters. They are exposed separately because they can also be passed into
    # various methods on the Layout object, which is a much more typical way of sending an action to
    # FileMaker.
    #
    # This method returns the Net::HTTP response object representing the response from FileMaker.
    #
    # For example, if you wanted to send a raw command to FileMaker to find the first 20 people in the
    # "Customers" database whose first name is "Bill" you might do this:
    #
    #   response = myServer.do_action(
    #     '-find',
    #     {
    #       "-db" => "Customers",
    #       "-lay" => "Details",
    #       "First Name" => "Bill"
    #     },
    #     { :max_records => 20 }
    #   )
    def do_action(account_name, password, action, args, options = {})
      post = args.merge(expand_options(options)).merge({action => ''})
      http_fetch(@host_name, @port, "/fmi/xml/fmresultset.xml", account_name, password, post)
    end
    
    def load_layout(layout)
      post = {'-db' => layout.db.name, '-lay' => layout.name, '-view' => ''}
      http_fetch(@host_name, @port, "/fmi/xml/FMPXMLLAYOUT.xml", layout.db.account_name, layout.db.password, post)
    end

    private
    
    def http_fetch(host_name, port, path, account_name, password, post_data, limit = 10)
      if limit == 0
         raise Rfm::Error::CommunicationError.new("While trying to reach the Web Publishing Engine, RFM was redirected too many times.")
      end

      if @state[:log_actions] == true
        qs = post_data.collect{|key,val| "#{CGI::escape(key.to_s)}=#{CGI::escape(val.to_s)}"}.join("&")
        warn "#{@scheme}://#{@host_name}:#{@port}#{path}?#{qs}"
      end

      request = Net::HTTP::Post.new(path)
      request.basic_auth(account_name, password)
      request.set_form_data(post_data)

      response = Net::HTTP.start(host_name, port) { |http|
        http.request(request)
      }
      
      if @state[:log_responses] == true
        response.to_hash.each {|key, value|
          warn "#{key}: #{value}"
        }
        warn response.body
      end

      case response
      when Net::HTTPSuccess
        response
      when Net::HTTPRedirection
        if @state[:warn_on_redirect]
          warn "The web server redirected to " + response['location'] + ". You should revise your connection hostname or fix your server configuration if possible to improve performance."
        end
        newloc = URI.parse(response['location'])
        http_fetch(newloc.host, newloc.port, newloc.request_uri, account_name, password, post_data, limit - 1)
      when Net::HTTPUnauthorized
        msg = "The account name (#{account_name}) or password provided is not correct (or the account doesn't have the fmxml extended privilege)."
        raise Rfm::Error::AuthenticationError.new(msg)
      when Net::HTTPNotFound
        msg = "Could not talk to FileMaker because the Web Publishing Engine is not responding (server returned 404)."
        raise Rfm::Error::CommunicationError.new(msg)
      else
        msg = "Unexpected response from server: #{result.code} (#{result.class.to_s}). Unable to communicate with the Web Publishing Engine."
        raise Rfm::Error::CommunicationError.new(msg)
      end
    end

    def expand_options(options)
      result = {}
      options.each {|key,value|
        case key
          when :max_records:
            result['-max'] = value
          when :skip_records:
            result['-skip'] = value
          when :sort_field:
            if value.kind_of? Array
              if value.size > 9
                raise Rfm::Error::ParameterError.new(":sort_field can have at most 9 fields, but you passed an array with #{value.size} elements.")
              end
              value.each_index {|i|
                result["-sortfield.#{i+1}"] = value[i]
              }
            else
              result["-sortfield.1"] = value
            end
          when :sort_order:
            result['-sortorder'] = value
          when :post_script:
            if value.class == Array
              result['-script'] = value[0]
              result['-script.param'] = value[1]
            else
              result['-script'] = value
            end
          when :pre_find_script:
            if value.class == Array
              result['-script.prefind'] = value[0]
              result['-script.prefind.param'] = value[1]
            else
              result['-script.presort'] = value
            end
          when :pre_sort_script:
            if value.class == Array
              result['-script.presort'] = value[0]
              result['-script.presort.param'] = value[1]
            else
              result['-script.presort'] = value
            end
          when :response_layout:
            result['-lay.response'] = value
          when :logical_operator:
            result['-lop'] = value
          when :modification_id:
            result['-modid'] = value
          else
            raise Rfm::Error::ParameterError.new("Invalid option: #{key} (are you using a string instead of a symbol?)")
        end
      }
      result
    end
    
  end
  
  # The Database object represents a single FileMaker Pro database. When you retrieve a Database
  # object from a server, its account name and password are set to the account name and password you 
  # used when initializing the Server object. You can override this of course:
  #
  #   myDatabase = myServer["Customers"]
  #   myDatabase.account_name = "foo"
  #   myDatabase.password = "bar"
  #
  # =Accessing Layouts
  #
  # All interaction with FileMaker happens through a Layout object. You can get a Layout object
  # from the Database object like this:
  #
  #   myLayout = myDatabase["Details"]
  #
  # This code gets the Layout object representing the layout called Details in the database.
  #
  # Note: RFM does not talk to the server when you retrieve a Layout object in this way. Instead, it
  # simply assumes you know what you're talking about. If the layout you specify does not exist, you 
  # will get no error at this point. Instead, you'll get an error when you use the Layout object methods
  # to talk to FileMaker. This makes debugging a little less convenient, but it would introduce too much
  # overhead to hit the server at this point.
  #
  # The Database object has a +layout+ attribute that provides alternate access to Layout objects. It acts
  # like a hash of Layout objects, one for each accessible layout in the database. So, for example, you
  # can do this if you want to print out a list of all layouts:
  # 
  #   myDatabase.layout.each {|layout|
  #     puts layout.name
  #   }
  # 
  # The Database::layout attribute is actually a LayoutFactory object, although it subclasses hash, so it
  # should work in all the ways you expect. Note, though, that it is completely empty until the first time
  # you attempt to access its elements. At that (lazy) point, it hits FileMaker, loads in the list of layouts,
  # and constructs a Layout object for each one. In other words, it incurrs no overhead until you use it.
  #
  # =Accessing Scripts
  #
  # If for some reason you need to enumerate the scripts in a database, you can do so:
  #  
  #   myDatabase.script.each {|script|
  #     puts script.name
  #   }
  # 
  # The Database::script attribute is actually a ScriptFactory object, although it subclasses hash, so it
  # should work in all the ways you expect. Note, though, that it is completely empty until the first time
  # you attempt to access its elements. At that (lazy) point, it hits FileMaker, loads in the list of scripts,
  # and constructs a Script object for each one. In other words, it incurrs no overhead until you use it. 
  #
  # Note: You don't need a Script object to _run_ a script (see the Layout object instead).
  #
  # =Attributes
  # 
  # In addition to the +layout+ attribute, Server has a few other useful attributes:
  #
  # * *server* is the Server object this database comes from
  # * *name* is the name of this database
  # * *state* is a hash of all server options used to initialize this server
  class Database
  
    # Initialize a database object. You never really need to do this. Instead, just do this:
    # 
    #   myServer = Rfm::Server.new(...)
    #   myDatabase = myServer["Customers"]
    #
    # This sample code gets a database object representing the Customers database on the FileMaker server.
    def initialize(name, server)
      @name = name
      @server = server
      @account_name = server.state[:account_name] or ""
      @password = server.state[:password] or ""
      @layout = Rfm::Factory::LayoutFactory.new(server, self)
      @script = Rfm::Factory::ScriptFactory.new(server, self)
    end
    
    attr_reader :server, :name, :account_name, :password, :layout, :script
    attr_writer :account_name, :password

    # Access the Layout object representing a layout in this database. For example:
    #
    #   myDatabase['Details']
    #
    # would return a Layout object representing the _Details_
    # layout in the database.
    #
    # Note: RFM never talks to the server until you perform an action. The Layout object
    # returned is created on the fly and assumed to refer to a valid layout, but you will
    # get no error at this point if the layout you specify doesn't exist. Instead, you'll
    # receive an error when you actually try to perform some action it.
    def [](layout_name)
      self.layout[layout_name]
    end

  end

  # The Layout object represents a single FileMaker Pro layout. You use it to interact with 
  # records in FileMaker. *All* access to FileMaker data is done through a layout, and this
  # layout determins which _table_ you actually hit (since every layout is explicitly associated
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
  # * *sort_order* can be +desc+ (descending) or +asc+ (ascending) and determines the order
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
    #   myServer = Rfm::Server.new(...)
    #   myDatabase = myServer["Customers"]
    #   myLayout = myDatabase["Details"]
    #
    # This sample code gets a layout object representing the Details layout in the Customers database
    # on the FileMaker server.
    # 
    # In case it isn't obvious, this is more easily expressed this way:
    #
    #   myServer = Rfm::Server.new(...)
    #   myLayout = myServer["Customers"]["Details"]
    def initialize(name, db)
      @name = name
      @db = db
      
      @loaded = false
      @field_controls = Rfm::Util::CaseInsensitiveHash.new
      @value_lists = Rfm::Util::CaseInsensitiveHash.new
    end
    
    attr_reader :name, :db
    
    def field_controls
      load if !@loaded
      @field_controls
    end
    
    def value_lists
      load if !@loaded
      @value_lists
    end
    
    # Returns a ResultSet object containing _every record_ in the table associated with this layout.
    def all(options = {})
      get_records('-findall', {}, options)
    end
    
    # Returns a ResultSet containing a single random record from the table associated with this layout.
    def any(options = {})
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
    def find(hash_or_recid, options = {})
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
    
    def load
      @loaded = true
      fmpxmllayout = @db.server.load_layout(self).body
      doc = REXML::Document.new(fmpxmllayout)
      root = doc.root
      
      # check for errors
      error = root.elements['ERRORCODE'].text.to_i
      raise Rfm::Error::FileMakerError.getError(error) if error != 0
      
      # process valuelists
      if root.elements['VALUELISTS'].size > 0
        root.elements['VALUELISTS'].each_element('VALUELIST') { |valuelist|
          name = valuelist.attributes['NAME']
          @value_lists[name] = valuelist.elements.collect {|e| e.text}
        }
        @value_lists.freeze
      end
      
      # process field controls
      root.elements['LAYOUT'].each_element('FIELD') { |field| 
        name = field.attributes['NAME']
        style = field.elements['STYLE'].attributes['TYPE']
        value_list_name = field.elements['STYLE'].attributes['VALUELIST']
        value_list = @value_lists[value_list_name] if value_list_name != ''
        field_control = FieldControl.new(name, style, value_list_name, value_list)
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
      }
      @field_controls.freeze      
    end
    
    def get_records(action, extra_params = {}, options = {})
      Rfm::Result::ResultSet.new(
        @db.server, @db.server.do_action(@db.account_name, @db.password, action, params().merge(extra_params), options).body,
        self)
    end
    
    def params
      {"-db" => @db.name, "-lay" => self.name}
    end
  end

  # The FieldControl object represents a field on a FileMaker layout. You can find out what field
  # style the field uses, and the value list attached to it.
  #
  # =Attributes
  #
  # * *name* is the name of the field
  #
  # * *style* is any one of:
  # * * :edit_box - a normal editable field
  # * * :scrollable - an editable field with scroll bar
  # * * :popup_menu - a pop-up menu
  # * * :checkbox_set - a set of checkboxes
  # * * :radio_button_set - a set of radio buttons
  # * * :popup_list - a pop-up list
  # * * :calendar - a pop-up calendar
  #
  # * *value_list_name* is the name of the attached value list, if any
  # 
  # * *value_list* is an array of strings representing the value list items, or nil
  #   if this field has no attached value list
  class FieldControl
    def initialize(name, style, value_list_name, value_list)
      @name = name
      case style
      when "EDITTEXT"
        @style = :edit_box
      when "POPUPMENU"
        @style = :popup_menu
      when "CHECKBOX"
        @style = :checkbox_set
      when "RADIOBUTTONS"
        @style = :radio_button_set
      when "POPUPLIST"
        @style = :popup_list
      when "CALENDAR"
        @style = :calendar
      when "SCROLLTEXT"
        @style = :scrollable
      end
      @value_list_name = value_list_name
      @value_list = value_list
    end
    
    attr_reader :name, :style, :value_list_name, :value_list

  end

  # The Script object represents a FileMaker script. At this point, the Script object exists only so
  # you can enumrate all scripts in a Database (which is a rare need):
  # 
  #   myDatabase.script.each {|script|
  #     puts script.name
  #   }
  #
  # If you want to _run_ a script, see the Layout object instead.
  class Script
    def initialize(name, db)
      @name = name
      @db = db
    end
    
    attr_reader :name
  end

end