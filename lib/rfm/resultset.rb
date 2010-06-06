# This module includes classes that represent FileMaker data. When you communicate with FileMaker
# using, ie, the Layout object, you typically get back ResultSet objects. These contain Records,
# which in turn contain Fields, Portals, and arrays of data.
#
# Author::    Geoff Coffey  (mailto:gwcoffey@gmail.com)
# Copyright:: Copyright (c) 2007 Six Fried Rice, LLC and Mufaddal Khumri
# License::   See MIT-LICENSE for details
require 'nokogiri'
require 'bigdecimal'
require 'rfm/record'
require 'rfm/metadata/field'

module Rfm

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
  # The ResultSet object has these attributes:
  #
  # * *field_meta* is a hash with field names for keys and Field objects for values; it provides 
  #   info about the fields in the ResultSet
  #
  # * *portal_meta* is a hash with table occurrence names for keys and arrays of Field objects for values;
  #   it provides metadata about the portals in the ResultSet and the Fields on those portals

  class Resultset < Array
    
    attr_reader :layout
    attr_reader :field_meta, :portal_meta
    attr_reader :date_format, :time_format, :timestamp_format
    attr_reader :total_count, :foundset_count
    
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
    
    def initialize(server, xml_response, layout, portals=nil)
      @layout = layout
      @field_meta ||= Rfm::CaseInsensitiveHash.new
      @portal_meta ||= Rfm::CaseInsensitiveHash.new
      @include_portals  = portals 
      
      doc = Nokogiri.XML(remove_namespace(xml_response))
      
      error = doc.xpath('/fmresultset/error').attribute('code').value.to_i
      check_for_errors(error, server.state[:raise_on_401])

      datasource        = doc.xpath('/fmresultset/datasource')
      meta              = doc.xpath('/fmresultset/metadata')
      resultset         = doc.xpath('/fmresultset/resultset')

      @date_format      = convert_date_time_format(datasource.attribute('date-format').value)
      @time_format      = convert_date_time_format(datasource.attribute('time-format').value)
      @timestamp_format = convert_date_time_format(datasource.attribute('timestamp-format').value)

      @foundset_count   = resultset.attribute('count').value.to_i
      @total_count      = datasource.attribute('total-count').value.to_i

      parse_fields(meta)
      parse_portals(meta) if @include_portals
      
      Rfm::Record.build_records(resultset.xpath('record'), self, @field_meta, @layout)
      
    end
    
    private
      def remove_namespace(xml)
        xml.gsub('xmlns="http://www.filemaker.com/xml/fmresultset" version="1.0"', '')
      end
    
      def check_for_errors(code, raise_401)
        raise Rfm::Error.getError(code) if code != 0 && (code != 401 || raise_401)
      end
    
      def parse_fields(meta)
        meta.xpath('field-definition').each do |field|
          @field_meta[field['name']] = Rfm::Metadata::Field.new(field)
        end
      end

      def parse_portals(meta)
        meta.xpath('relatedset-definition').each do |relatedset|
          table, fields = relatedset.attribute('table').value, {}

          relatedset.xpath('field-definition').each do |field|
            name = field.attribute('name').value.gsub(Regexp.new(table + '::'), '')
            fields[name] = Rfm::Metadata::Field.new(field)
          end

          @portal_meta[table] = fields
        end
      end
    
      def convert_date_time_format(fm_format)
        fm_format.gsub!('MM', '%m')
        fm_format.gsub!('dd', '%d')
        fm_format.gsub!('yyyy', '%Y')
        fm_format.gsub!('HH', '%H')
        fm_format.gsub!('mm', '%M')
        fm_format.gsub!('ss', '%S')
        fm_format
      end
    
  end
end