# Rfm

This library is no longer maintained. It is known to work up to Filemaker version 14. Beyond that there are no guarantee that it will work. There is currently a maintained fork that goes under a different gem name here: https://github.com/ginjo/rfm

~L

[![Build Status](https://travis-ci.org/lardawge/rfm.png?branch=master)](https://travis-ci.org/lardawge/rfm)
[![Code Quality](https://codeclimate.com/badge.png)](https://codeclimate.com/github/lardawge/rfm)

## Installation

Terminal:

```bash
gem install lardawge-rfm
```

Once the gem is installed, you can use rfm in your ruby scripts by requiring it:

```ruby
require 'rubygems'
require 'rfm'
```
### In Rails >= 3.0

In the Gemfile:

```ruby
gem 'lardawge-rfm'
```

## Connecting

IMPORTANT:SSL and Certificate verification are on by default. Please see Server#new in rdocs for explanation and setup.
You connect with the Rfm::Server object. This little buddy will be your window into FileMaker data.

```ruby
require 'rfm'

my_server = Rfm::Server.new(
  :host => 'myservername',
  :account_name => 'user',
  :password => 'pw',
  :ssl => false
)
```

if your web publishing engine runs on a port other than 80, you can provide the port number as well:

```ruby
my_server = Rfm::Server.new(
  :host => 'myservername',
  :account_name => 'user',
  :password => 'pw',
  :port => 8080,
  :ssl => false
)
```

## Databases and Layouts

All access to data in FileMaker's XML interface is done through layouts, and layouts live in databases. The Rfm::Server object has a collection of databases called 'db'. So to get ahold of a database called "My Database", you can do this:

```ruby
my_db = my_server.db["My Database"]
```

As a convenience, you can do this too:

```ruby
my_db = my_server["My Database"]
```

Finally, if you want to introspect the server and find out what databases are available, you can do this:

```ruby
all_dbs = my_server.db.all
```

In any case, you get back Rfm::Database objects. A database object in turn has a property called "layout":

```ruby
my_layout = my_db.layout["My Layout"]
```

Again, for convenience:

```ruby
my_layout = my_db["My Layout"]
```

And to get them all:

```ruby
all_layouts = my_db.layout.all
```

Bringing it all together, you can do this to go straight from a server to a specific layout:

```ruby
my_layout = my_server["My Database"]["My Layout"]
```

## Working with Layouts

Once you have a layout object, you can start doing some real work. To get every record from the layout:

```ruby
my_layout.all   # be careful with this
```

To get a random record:

```ruby
my_layout.any
```

To find every record with "Arizona" in the "State" field:

```ruby
my_layout.find({"State" => "Arizona"})
```

To add a new record with my personal info:

```ruby
my_layout.create({
  :first_name => "Geoff",
  :last_name => "Coffey",
  :email => "gwcoffey@gmail.com"}
)
```

Notice that in this case I used symbols instead of strings for the hash keys. The API will accept either form, so if your field names don't have whitespace or punctuation, you might prefer the symbol notation.

To edit the record whos recid (filemaker internal record id) is 200:

```ruby
my_layout.edit(200, {:first_name => 'Mamie'})
```

Note: See the "Record Objects" section below for more on editing records.

To delete the record whose recid is 200:

```ruby
my_layout.delete(200)
```

All of these methods return an Rfm::Result::ResultSet object (see below), and every one of them takes an optional parameter (the very last one) with additional options. For example, to find just a page full of records, you can do this:

```ruby
my_layout.find({:state => "AZ"}, {:max_records => 10, :skip_records => 100})
```

For a complete list of the available options, see the "expand_options" method in the Rfm::Server object in the file named rfm_command.rb.

Finally, if filemaker returns an error when executing any of these methods, an error will be raised in your ruby script. There is one exception to this, though. If a find results in no records being found (FileMaker error # 401) I just ignore it and return you a ResultSet with zero records in it. If you prefer an error in this case, add :raise_on_401 => true to the options you pass the Rfm::Server when you create it.


## ResultSet and Record Objects

Any method on the Layout object that returns data will return a ResultSet object. Rfm::Result::ResultSet is a subclass of Array, so first and foremost, you can use it like any other array:

```ruby
my_result = my_layout.any
my_result.size  # returns '1'
my_result[0]    # returns the first record (an Rfm::Result::Record object)
```

The ResultSet object also tells you information about the fields and portals in the result. ResultSet#fields and ResultSet#portals are both standard ruby hashes, with strings for keys. The fields hash has Rfm::Result::Field objects for values. The portals hash has another hash for its values. This nested hash is the fields on the portal. This would print out all the field names:

```ruby
my_result.fields.each { |name, field| puts name }
```

This would print out the tables each portal on the layout is associated with. Below each table name, and indented, it will print the names of all the fields on each portal.

```ruby
my_result.portals.each { |table, fields|
  puts "table: #{table}"
  fields.each { |name, field| puts "\t#{name}"}
}
```

But most importantly, the ResultSet contains record objects. Rfm::Result::Record is a subclass of Hash, so it can be used in many standard ways. This code would print the value in the 'first_name' field in the first record of the ResultSet:

```ruby
my_record = my_result[0]
puts my_record["first_name"]
```

As a convenience, if your field names are valid ruby method names (ie, they don't have spaces or odd punctuation in them), you can do this instead:

```ruby
puts my_record.first_name
```

Since ResultSets are arrays and Records are hashes, you can take advantage of Ruby's wonderful expressiveness. For example, to get a comma-separated list of the full names of all the people in California, you could do this:

```ruby
my_layout.find(:state => 'CA').collect {|rec| "#{rec.first_name} #{rec.last_name}"}.join(", ")
```

Record objects can also be edited:

```ruby
my_record.first_name = 'Isabel'
```

Once you have made a series of edits, you can save them back to the database like this:

```ruby
my_record.save
```

The save operation causes the record to be reloaded from the database, so any changes that have been made outside your script will also be picked up after the save.

If you want to detect concurrent modification, you can do this instead:

```ruby
my_record.save_if_not_modified
```

This version will refuse to update the database and raise an error if the record was modified after it was loaded but before it was saved.

Record objects also have portals. While the portals in a ResultSet tell you about the tables and fields the portals show, the portals in a Record have the actual data. For example, if an Order record has Line Item records, you could do this:

```ruby
my_order = order_layout.any(include_portals: true)[0]  # the [0] is important!
my_lines = my_order.portals["Line Items"]
```

At the end of the previous block of code, my_lines is an array of Record objects. In this case, they are the records in the "Line Items" portal for the particular order record. You can then operate on them as you would any other record.

NOTE: Fields on a portal have the table name and the "::" stripped off of their names if they belong to the table the portal is tied to. In other words, if our "Line Items" portal includes a quantity field and a price field, you would do this:

```ruby
my_lines[0]["Quantity"]
my_lines[0]["Price"]
```

You would NOT do this:

```ruby
my_lines[0]["Line Items::Quantity"]
my_lines[0]["Line Items::Quantity"]
```

My feeling is that the table name is redundant and cumbersome if it is the same as the portal's table. This is also up for debate.

Again, you can string things together with Ruby. This will calculate the total dollar amount of the order:

```ruby
total = 0.0
my_order.portals["Line Items"].each {|line| total += line.quantity * line.price}
```

## Data Types

FileMaker's field types are coerced to Ruby types thusly:

  Text Field -> String object
  Number Field -> BigDecimal object  # see below
  Date Field -> Date object
  Time Field -> DateTime object # see below
  TimeStamp Field -> DateTime object
  Container Field -> URI object

FileMaker's number field is insanely robust. The only data type in ruby that can handle the same magnitude and precision of a FileMaker number is Ruby's BigDecimal. (This is an extension class, so you have to require 'bigdecimal' to use it yourself). Unfortuantely, BigDecimal is not a "normal" ruby numeric class, so it might be really annoying that your tiny filemaker numbers have to go this route. This is a great topic for debate.

Also, Ruby doesn't have a Time type that stores just a normal time (with no date attached). The Time class in ruby is a lot like DateTime, or a Timestamp in FileMaker. When I get a Time field from FileMaker, I turn it into a DateTime object, and set its date to the oldest date Ruby supports. You can still compare these in all the normal ways, so this should be fine, but it will look weird if you, ie, to_s one and see an odd date attached to your time.

Finally, container fields will come back as URI objects. You can:

  - use Net::HTTP to download the contents of the container field using this URI
  - to_s the URI and use it as the src attribute of an HTML image tag
  - etc...

Specifically, the URI refers to the _contents_ of the container field. When accessed, the file, picture, or movie in the field will be downloaded.

## Troubleshooting

There are two cheesy methods to help track down problems. When you create a server object, you can provide two additional optional parameters:

:log_actions
When this is 'true' your script will write every URL it sends to the web publishing engine to standard out. For the rails users, this means the action url will wind up in your WEBrick or Mongrel log. If you can't make sense of what you're getting, you might try copying the URL into your browser to see what is actually coming back from FileMaker.

:log_responses
When this is 'true' your script will dump the actual response it got from FileMaker to standard out (again, in rails, check your logs).

So, for an annoying, but detailed load of output, make a connection like this:

```ruby
my_server # Rfm::Server.new(
  :host #> 'myservername',
  :account_name #> 'user',
  :password #> 'pw',
  :log_actions #> true,
  :log_responses #> true
)
```

## Copyright

Copyright (c) 2007 Six Fried Rice, LLC and Mufaddal Khumr. See LICENSE for details.
