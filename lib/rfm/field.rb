module Rfm
  # The Field object represents a single FileMaker field. It *does not hold the data* in the field. Instead,
  # it serves as a source of metadata about the field. For example, if you're script is trying to be highly
  # dynamic about its field access, it may need to determine the data type of a field at run time. Here's
  # how:
  #
  #   field_name = "Some Field Name"
  #   case my_record.fields[field_name].result
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
  # * *control& is a FieldControl object representing the style and value list information associated
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
    # ResultSet#fields
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