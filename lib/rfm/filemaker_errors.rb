module Rfm
  
  # FileMaker is the base class for the error hierarchy.
  # 
  # One could raise a FileMaker by doing:
  #   raise Rfm::FilemakerError.get(102)
  #
  # It also takes an optional argument to give a more discriptive error message:
  #   err = Rfm::FilemakerError.get(102, 'add description with more detail here')
  # 
  # The above code would return a FieldMissing instance. Your could use this instance to raise that appropriate
  # exception:
  # 
  #   raise err 
  # 
  # You could access the specific error code by accessing:
  #   
  #   err.code
  module FilemakerError
    
    # This method returns the appropriate FileMaker object depending on the error code passed to it. It
    # also accepts an optional message.
    def self.get(code, message=nil)
      klass = find_by_code(code)
      error_message = build_message(klass, code, message)
      error = instantiate_klass(klass, error_message)
      error.code = code
      error
    end
    
    def self.build_message(klass, code, message=nil) #:nodoc:
      msg =  ": #{message}"
      msg << " " unless message.nil?
      msg << "(FileMaker Error ##{code})"
      "#{klass.to_s.gsub(/Rfm::/, '')}Error occurred#{msg}"
    end
    
    def self.instantiate_klass(klass, message=nil) #:nodoc:
      klass.new(message)
    end
    
    def self.find_by_code(code) #:nodoc:
      case code
      when 0..99
        System
      when 100..199
        if code == 101; RecordMissing
        elsif code == 102; FieldMissing
        elsif code == 104; ScriptMissing
        elsif code == 105; LayoutMissing
        elsif code == 106; TableMissing
        else; Missing; end
      when 203..299
        if code == 200; RecordAccessDenied
        elsif code == 201; FieldCannotBeModified
        elsif code == 202; FieldAccessIsDenied
        else; Security; end
      when 300..399
        if code == 301; RecordInUse
        elsif code == 302; TableInUse
        elsif code == 306; RecordModIdDoesNotMatch
        else; Concurrency; end
      when 400..499
       if code == 401; NoRecordsFound
       else; General; end
      when 500..599
        if code == 500; DateValidation
        elsif code == 501; TimeValidation
        elsif code == 502; NumberValidation
        elsif code == 503; RangeValidation
        elsif code == 504; UniqueValidation
        elsif code == 505; ExistingValidation
        elsif code == 506; ValueListValidation
        elsif code == 507; ValidationCalculation
        elsif code == 508; InvalidFindModeValue
        elsif code == 511; MaximumCharactersValidation
        else; Validation
        end
      when 800..899
        if code == 802; UnableToOpenFile
        else; File; end
      else
        Unknown
      end
    end
  end
  
  class Rfm < StandardError #:nodoc:
    attr_accessor :code
  end
  
  class Unknown < Rfm #:nodoc:
  end
  
  class System < Rfm #:nodoc:
  end
  
  class Missing < Rfm  #:nodoc:
  end
  
  class RecordMissing < Missing #:nodoc:
  end

  class FieldMissing < Missing #:nodoc:
  end

  class ScriptMissing < Missing #:nodoc: 
  end

  class LayoutMissing < Missing #:nodoc: 
  end

  class TableMissing < Missing #:nodoc:
  end

  class Security < Rfm #:nodoc:
  end
  
  class RecordAccessDenied < Security #:nodoc:
  end

  class FieldCannotBeModified < Security #:nodoc:
  end

  class FieldAccessIsDenied < Security #:nodoc:
  end
  
  class Concurrency < Rfm #:nodoc:
  end
  
  class RecordInUse < Concurrency #:nodoc:
  end

  class TableInUse < Concurrency #:nodoc:
  end

  class RecordModIdDoesNotMatch < Concurrency #:nodoc:
  end

  class General < Rfm #:nodoc:
  end

  class NoRecordsFound < General #:nodoc:
  end
   
  class Validation < Rfm #:nodoc:
  end 

  class DateValidation < Validation #:nodoc:
  end

  class TimeValidation < Validation #:nodoc:
  end
  
  class NumberValidation < Validation #:nodoc: 
  end
  
  class RangeValidation < Validation #:nodoc:
  end

  class UniqueValidation < Validation #:nodoc:
  end
  
  class ExistingValidation < Validation #:nodoc:
  end

  class ValueListValidation < Validation #:nodoc:
  end

  class ValidationCalculation < Validation #:nodoc:
  end

  class InvalidFindModeValue < Validation #:nodoc:
  end

  class MaximumCharactersValidation < Validation #:nodoc:
  end

  class File < Rfm #:nodoc:
  end 

  class UnableToOpenFile < File #:nodoc:
  end
end