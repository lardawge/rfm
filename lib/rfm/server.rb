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
    # * *ssl* +false+ if you want to turn SSL (HTTPS) off when connecting to FileMaker (default is +true+)
    #
    # If you are using SSL and want to verify the certificate use the following options:
    #
    # * *pem* full path to pem file or false to turn certificate verification off. (Root cert from certificate authority who issued certificate.
    #   If self signed certificate do not use this option!!).
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
    # Example using SSL without verification:
    #           
    #   my_server = Rfm::Server.new(
    #           :host => 'localhost',
    #           :account_name => 'sample',
    #           :password => '12345'
    #           :pem => false
    #           )
    #           
    # Example using SSL with cert verification:
    # 
    #   my_server = Rfm::Server.new(
    #            :host => 'localhost',
    #            :account_name => 'sample',
    #            :password => '12345',
    #            :pem => '/cert/example.pem' 
    #            )
    
    def initialize(options={})
      @options = Rfm.options(options)
      @db      = Factories::DbFactory.new
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
    
    def [](name)
      db(name)
    end
    
    def databases
      @db.all
    end
    
  end
end