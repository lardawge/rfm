require 'net/https'
require 'cgi'

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
  #   my_db = my_server.db("Customers")
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
  # can do this if you want to print out a list of all databases on the server:
  # 
  #   my_server.databases.each { |database| puts database.name }
  # 
  # The Server::db attribute is actually a DbFactory object, although it subclasses hash, so it should work
  # in all the ways you expect. Note, though, that it is completely empty until the first time you attempt 
  # to access its elements. At that (lazy) point, it hits FileMaker, loads in the list of databases, and
  # constructs a Database object for each one. In other words, it incurs no overhead until you use it.
  #
  # =Attributes
  # 
  # In addition to the +db+ attribute, Server has a few other useful attributes:
  #
  # * *host_name* is the host name this server points to
  # * *port* is the port number this server communicates on
  # * *state* is a hash of all server options used to initialize this server
  
  
  
  # The Database object represents a single FileMaker Pro database. When you retrieve a Database
  # object from a server, its account name and password are set to the account name and password you 
  # used when initializing the Server object. You can override this of course:
  #
  #   my_db = my_server.db("Customers")
  #   my_db.account_name = "foo"
  #   my_db.password = "bar"
  #
  # =Accessing Layouts
  #
  # All interaction with FileMaker happens through a Layout object. You can get a Layout object
  # from the Database object like this:
  #
  #   my_layout = my_db.layout("Details")
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
  #   my_db.layouts.each { |layout| puts layout.name }
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
  #   my_db.scripts.each { |script| puts script.name }
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
  # * *options* is a hash of all server options used to initialize this server
  class Server
    attr_reader :options

    # To create a Server object, you typically need at least a host name:
    # 
    #   my_server = Rfm::Server.new(:host => 'my.host.com')
    #
    # Several other options are supported:
    #
    # * *host* the hostname of the Web Publishing Engine (WPE) server (defaults to 'localhost')
    #
    # * *port* the port number the WPE is listening no (defaults to 80 unless *ssl* +true+ which sets it to 443)
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
    #
    #SSL Options (SSL AND CERTIFICATE VERIFICATION ARE ON BY DEFAULT):
    #
    # * *ssl* +false+ if you want to turn SSL (HTTPS) off when connecting to connect to FileMaker (default is +true+)
    #
    # If you are using SSL and want to verify the certificate use the following options:
    #
    # * *root_cert* +false+ if you do not want to verify your SSL session (default is +true+). 
    #   You will want to turn this off if you are using a self signed certificate and do not have a certificate authority cert file.
    #   If you choose this option you will need to provide a cert *root_cert_name* and *root_cert_path* (if not in root directory).
    #
    # * *root_cert_name* name of pem file for certificate verification (Root cert from certificate authority who issued certificate.
    #   If self signed certificate do not use this option!!). You can download the entire bundle of CA Root Certificates
    #   from http://curl.haxx.se/ca/cacert.pem. Place the pem file in config directory.
    #
    # * *root_cert_path* path to cert file. (defaults to '/' if no path given)
    #
    #Configuration Examples:    
    #
    # Example to turn off SSL:
    # 
    #   my_server = Rfm::Server.new(
    #           :host => 'localhost',
    #           :account_name => 'sample',
    #           :password => '12345',
    #           :ssl => false 
    #           )
    #           
    # Example using SSL without *root_cert*:
    #           
    #   my_server = Rfm::Server.new(
    #           :host => 'localhost',
    #           :account_name => 'sample',
    #           :password => '12345',
    #           :root_cert => false 
    #           )
    #           
    # Example using SSL with *root_cert* at file root:
    # 
    #   my_server = Rfm::Server.new(
    #            :host => 'localhost',
    #            :account_name => 'sample',
    #            :password => '12345',
    #            :root_cert_name => 'example.pem' 
    #            )
    #            
    # Example using SSL with *root_cert* specifying *root_cert_path*:
    # 
    #   my_server = Rfm::Server.new(
    #            :host => 'localhost',
    #            :account_name => 'sample',
    #            :password => '12345',
    #            :root_cert_name => 'example.pem'
    #            :root_cert_path => '/usr/cert_file/'
    #            )
    
    def initialize(user_options={})
      @options = {
        :host => 'localhost',
        :port => 80,
        :ssl => true,
        :root_cert => true,
        :root_cert_name => '',
        :root_cert_path => '/',
        :account_name => '',
        :password => '',
        :log_actions => false,
        :log_responses => false,
        :warn_on_redirect => true,
        :raise_on_401 => false
      }.merge(user_options)
    
      @scheme         = @options[:ssl] ? "https" : "http"
      @options[:port] = @options[:ssl] && user_options[:port].nil? ? 443 : @options[:port]
      
      @db = Factories::DbFactory.new(self)
    end
    
    # Access the database object representing a database on the server. For example:
    #
    #   myServer.db('Customers')
    #
    # would return a Database object representing the _Customers_
    # database on the server.
    #
    # Note: RFM never talks to the server until you perform an action. The database object
    # returned is created on the fly and assumed to refer to a valid database, but you will
    # get no error at this point if the database you access doesn't exist. Instead, you'll
    # receive an error when you actually try to perform some action on a layout from this
    # database.
    def db(name=nil)
      return @db if name.nil?
      @db[name]
    end
    
    def [](dbname)
      db(dbname)
    end
    
    def databases
      @db.all
    end
    
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
      http_fetch(@options[:host], @options[:port], "/fmi/xml/fmresultset.xml", account_name, password, post)
    end
    
    def http_fetch(host_name, port, path, account_name, password, post_data, limit=10)
      raise CommunicationError.new("While trying to reach the Web Publishing Engine, RFM was redirected too many times.") if limit == 0
    
      if @options[:log_actions]
        qs = post_data.collect { |key,value| "#{CGI::escape(key.to_s)}=#{CGI::escape(value.to_s)}" }.join("&")
        warn "#{@scheme}://#{@options[:host]}:#{@options[:port]}#{path}?#{qs}"
      end
    
      request = Net::HTTP::Post.new(path)
      request.basic_auth(account_name, password)
      request.set_form_data(post_data)
    
      response = Net::HTTP.new(host_name, port)
    
      if @options[:ssl]
        response.use_ssl = true
        if @options[:root_cert]
          response.verify_mode = OpenSSL::SSL::VERIFY_PEER
          response.ca_file = File.join(@options[:root_cert_path], @options[:root_cert_name])
        else
          response.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end

      response = response.start { |http| http.request(request) }
    
      if @options[:log_responses]
        response.to_hash.each { |key, value| warn "#{key}: #{value}" }
        warn response.body
      end
    
      case response
      when Net::HTTPSuccess
        response
      when Net::HTTPRedirection
        if @options[:warn_on_redirect]
          warn "The web server redirected to " + response['location'] + 
          ". You should revise your connection hostname or fix your server configuration if possible to improve performance."
        end
        newloc = URI.parse(response['location'])
        http_fetch(newloc.host, newloc.port, newloc.request_uri, account_name, password, post_data, limit - 1)
      when Net::HTTPUnauthorized
        msg = "The account name (#{account_name}) or password provided is not correct (or the account doesn't have the fmxml extended privilege)."
        raise AuthenticationError.new(msg)
      when Net::HTTPNotFound
        msg = "Could not talk to FileMaker because the Web Publishing Engine is not responding (server returned 404)."
        raise CommunicationError.new(msg)
      else
        msg = "Unexpected response from server: #{result.code} (#{result.class.to_s}). Unable to communicate with the Web Publishing Engine."
        raise CommunicationError.new(msg)
      end
    end
    
    private
    
      def expand_options(options)
        result = {}
        options.each do |key,value|
          case key
          when :max_records
            result['-max'] = value
          when :skip_records
            result['-skip'] = value
          when :sort_field
            if value.kind_of? Array
              raise ParameterError.new(":sort_field can have at most 9 fields, but you passed an array with #{value.size} elements.") if value.size > 9
              value.each_index { |i| result["-sortfield.#{i+1}"] = value[i] }
            else
              result["-sortfield.1"] = value
            end
          when :sort_order
            if value.kind_of? Array
              raise ParameterError.new(":sort_order can have at most 9 fields, but you passed an array with #{value.size} elements.") if value.size > 9
              value.each_index { |i| result["-sortorder.#{i+1}"] = value[i] }
            else
              result["-sortorder.1"] = value
            end
          when :post_script
            if value.class == Array
              result['-script'] = value[0]
              result['-script.param'] = value[1]
            else
              result['-script'] = value
            end
          when :pre_find_script
            if value.class == Array
              result['-script.prefind'] = value[0]
              result['-script.prefind.param'] = value[1]
            else
              result['-script.presort'] = value
            end
          when :pre_sort_script
            if value.class == Array
              result['-script.presort'] = value[0]
              result['-script.presort.param'] = value[1]
            else
              result['-script.presort'] = value
            end
          when :response_layout
            result['-lay.response'] = value
          when :logical_operator
            result['-lop'] = value
          when :modification_id
            result['-modid'] = value
          else
            raise ParameterError.new("Invalid option: #{key} (are you using a string instead of a symbol?)")
          end
        end
        return result
      end
    
  end
end