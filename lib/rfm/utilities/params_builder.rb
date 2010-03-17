module Rfm
  module ParamsBuilder
    def self.parse(*params)
      base = {}
      base['-db'] = Rfm.options[:database] if Rfm.options[:database]
      
      params.each do |param|
        if param.kind_of? Hash
          base.merge!(expand(param))
        else
          base["-#{param.to_s}"] = ''
        end
      end
      
      base
    end
    
    def self.expand(options, result={})
      
      options.each do |key,value|
        case key
        when :max_records
          result['-max'] = value
        when :skip_records
          result['-skip'] = value
        when :sort_field
          if value.kind_of? Array
            raise ParameterError, ":sort_field can have at most 9 fields, but you passed an array with #{value.size}." if value.size > 9
            value.each_index { |i| result["-sortfield.#{i+1}"] = value[i] }
          else
            result["-sortfield.1"] = value
          end
        when :sort_order
          if value.kind_of? Array
            raise ParameterError, ":sort_order can have at most 9 fields, but you passed an array with #{value.size}." if value.size > 9
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
        when :layout
          result['-lay'] = value
        else
          result[key] = value
        end
      end
      return result
    end
  end
end