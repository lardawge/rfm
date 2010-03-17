require 'nokogiri'
# Rfm provides easy access to FileMaker Pro data. With it, Ruby scripts can
# perform finds, read records/fields, update data, and perform scripts using
# a simple ruby-like syntax.
#
# RFM uses FileMaker's XML API, so it requires:
# - FileMaker Server 9.0 or later
# - or FileMaker Server Advanced 7.0 or later
#
# = Quick Start
#
# Rfm is a Gem. As such, any ruby file that uses it, needs to have these two lines on top:
#
#   require "rubygems"
#   require "rfm"
#
# (If you don't have Rfm installed, use the +gem install rfm+ command to get it.)
#
# === The Server
#
# Everything in Rfm starts with the Server object. You create a Server object like this:
#
#   my_server = Rfm::Server.new(
#     :host => "yourhost",
#     :account_name => "someone",
#     :password => "secret"
#   )
#
# The Server object supports many other options, which you'll find explained in its
# documentation.
#
# Note: The account name and password are optional. You can instead provide them on 
# a per-database basis (using Database#account_name and Database#password). But 
# it is convenient to do it here because you often have one set of credentials
# across all databases. Also, you must provide an account_name and password if you
# want to ask the server for a list of available databases.
#
# === The Database
#
# Once you have a Server object, you can use it to get a Database. For example, if your
# database is called "Customers", you get it like this:
#
#   my_database = my_server.db("Customers")
#
# If you need to supply account and password info specifically for this database
# (rather than doing it at the Server level), do this:
#
#   my_database.account_name = "someone"
#   my_database.password = "secret"
#
# *IMPORTANT NOTE:* The account name you use to access FileMaker must have the
# +fmxml+ extended privilege. In other words, edit its privilege set and turn on
# "Access via XML Web Publishing (fmxml)" in the Extended Privileges section
# at the bottom-left of the Edit Privilege Set window. If you don't do this, 
# Rfm will report that it can't log in.
#
# === The Layout
#
# Every action you send to FileMaker always goes through a layout. This is how Rfm knows
# which table you want to work with, and which fields on that table you care about. This 
# should feel pretty familiar now:
#
#   my_layout = my_database.layout("Details")
#
# You might use layouts you already have, or make new layout just for Rfm. Just remember that
# if you delete a layout, or remove a field from a layout that your Rfm code uses, the 
# code will stop working.
#
# === Putting it Together
#
# Usually you don't care much about the intermediate Database object since it's a gateway object.
# So it is often easiest to combine all the above steps like this:
#
#   my_layout = my_server.db("Customers").layout("Details")
#
# === Performing Actions
#
# The Layout object can do a lot of things (see documentation for a full list). But
# in general, it involves records. For instance, you can find records:
#
#   result = my_layout.find({"First Name" => "Bill"})
#
# This will find everybody whose first name in Bill. All the Layout methods return a
# ResultSet object. It contains the records, as well as metadata about the fields and 
# portals on the layout. Usually you'll only concern yourself with the records (you
# can read about other methods in the ResultSet documentation). 
#
# ResultSet is a subclass of Array, Ruby's built in array type. So you can treat it just
# like any other array:
#
#   first_record = result.first
#   a_few_records = result[3,7]
#   record_count = result.size
#
# But usually you'll want to loop through them all.
#
#   result.each { |record| # do something with record here }
# 
# === Working with Records
#
# The records in a ResultSet are Record objects. They hold the actual data from
# FileMaker. Record subclasses Hash, another built in Ruby type, so you can use them like
# this:
#
#   full_name = record["First Name"] + ' ' + record["Last Name"]
#   info.merge(record)
#   record.each_value { |value| puts value }
#   if record.value?("Bill") then puts "Bill is in there somewhere"
# 
# The field name serves as the hash key, so these examples get fields called First Name and
# Last Name. (Note: Unlike a typical Ruby hash, Record objects are not case sensitive. You
# can say +record["first name"]+ or +record["FIRST NAME"]+ and it will still work.)
#
# A record object has the power to save changes to itself back to the database. For example:
#
#   records.each { |record| 
#     record["First Name"] = record["First Name"].upcase
#     record.save
#   }
#
# That concise code converts the First Name field to all uppercase in every record in the
# ResultSet. Note that each time you call Record::save, if the record has been modified, 
# Rfm has to send an action to FileMaker. A loop like the one above will be quite slow
# across many records. There is not fast way to update lots of records at once right now,
# although you might be able to accomplish it with a FileMaker script by passing a 
# parameter).
#
# === Editing and Deleting Records
#
# Any time you edit or delete a record, you *must* provide the record's internal record
# if. This is not the value in any field. Rather, it is the ID FileMaker assigns to the
# record internally. So an edit or delete is almost always a two-step process:
#
#   record = my_layout.find({"Customer ID" => "1234"}).first
#   my_layout.edit(record.record_id, {"First Name" => "Steve"})
#
# The code above first finds a Customer record. It then uses the Record#record_id method
# to discover that record's internal id. That id is passed to the Layout#edit method.
# The edit method also accepts a hash of record changes. In this case, we're changing
# the value in the First Name field to "Steve".
#
# To delete a record, you would do this instead:
#
#   record = my_layout.find({"Customer ID" => "1234"}).first
#   my_layout.delete(record.record_id)
#
# Finally, the Layout#find method can also find a record using its internal id:
#
#   record = my_layout.find(some_id)
#
# If the parameter you pass to Layout#find is not a hash, it is converted to a string
# and assumed to be a record id.
#
# === Performing Scripts
#
# Rfm can run a script in conjunction with any other action. For example, you might want
# to find a set of records, then run a script on them all. Or you may want to run a script
# when you delete a record. Here's how:
#
#   my_layout.find({"First Name" => "Bill"}, {:post_script => "Process Sales"})
#
# This code finds every record with "Bill" in the First Name field, then  runs the script
# called "Process Sales." You can control when the script actually runs, as explained in
# the documentation for Common Options for the Layout class.
#
# You can also pass a parameter to the script when it runs:
#
#   my_layout.find({"First Name" => "Bill"}, {:post_script => ["Process Sales", "all"]})
#
# This time, the text value "all" is passed to the script as a script parameter.
#
# =Notes on Rfm with Ruby on Rails
#
# Rfm is a great fit for Rails. But it isn't ActiveRecord, so you need to do things
# a little differently.
#
# === Configuration
#
# To avoid having to reconfigure your Server object in every Rails action, you 
# might add a configuration hash to the environment.rb. It can include all the
# options you need to connecto to your server:
#
#   RFM_CONFIG = {
#     :host => "yourhost",
#     :account_name => "someone",
#     :password => "secret",
#     :db => "Customers"
#   }
#
# Then you can get a server concisely:
#
#   my_server = Server.new(RFM_CONFIG).db(RFM_CONFIG[:db]).layout("My Layout")
#
# === Disable ActiveRecord
#
# If you're not using any SQL database in your Rails app, you'll quickly discover
# that Rails insists on a SQL database configuration anyway. This is easy to fix.
# Just turn off ActiveRecord. In the environment.rb, find the line that starts with
# +config.frameworks+. This is where you can disable the parts of Rails you're not 
# using. Uncomment the line and make it look like this:
#
#     config.frameworks -= [ :active_record ]
# 
# Now Rails will no longer insist on a SQL database.
path = File.expand_path(File.dirname(__FILE__))
$:.unshift(path) unless $:.include?(path)

module Rfm
  
  class CommunicationError < StandardError #:nodoc:
  end
  
  class ParameterError < StandardError #:nodoc:
  end
  
  class AuthenticationError < StandardError #:nodoc:
  end
  
  class PemFileMissingError < StandardError #:nodoc:  
  end
  
  class CaseInsensitiveHash < Hash #:nodoc:
    def []=(key, value)
      super(key.downcase, value)
    end
    def [](key)
      super(key.downcase)
    end
  end
  
  autoload :FileMakerError, "rfm/exceptions"
  autoload :ResultSet, "rfm/resultset"
  autoload :Record, "rfm/record"
  autoload :Field, "rfm/field"
  autoload :Database, 'rfm/database'
  autoload :FieldControl, 'rfm/field_control'
  autoload :Layout, 'rfm/layout'
  autoload :Server, 'rfm/server'
  autoload :Response, 'rfm/response'
  
  autoload :Factories, 'rfm/utilities/factories'
  autoload :ParamsBuilder, 'rfm/utilities/params_builder'
  
  def self.options(options={})
    @options ||= {
      :host => 'localhost',
      :port => 80,
      :ssl => true,
      :pem => '/not_found.pem',
      :account_name => '',
      :password => '',
      :warn_on_redirect => true,
      :raise_on_401 => false,
      :log_actions => false,
      :log_responses => false
    }.merge(options)
  end
end