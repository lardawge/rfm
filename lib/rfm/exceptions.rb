module Rfm
  
  # FileMakerError is the base class for the error hierarchy.
  # 
  # One could raise a FileMakerError by doing:
  #   raise Rfm::FileMakerError.get(102)
  #
  # It also takes an optional argument to give a more discriptive error message:
  #   err = Rfm::FileMakerError.get(102, 'add description with more detail here')
  # 
  # The above code would return a FieldMissingError instance. Your could use this instance to raise that appropriate
  # exception:
  # 
  #   raise err 
  # 
  # You could access the specific error code by accessing:
  #   
  #   err.code
  class FileMakerError < RfmError
    attr_accessor :code
    
    # This method instantiates and returns the appropriate FileMakerError object depending on the error code passed to it. It
    # also accepts an optional message.
    def self.get(code, message=nil)
      error = instantiate_error(find_error_by_code(code), cource_message(code, message))
      error.code = code
      return error
    end
    
    # TODO Remove in next major release
    def self.getError(code, message=nil) #:nodoc:
      warn "The #getError is deprecated and will be replaced by #get."
      get(code, message)
    end
    
    def self.cource_message(code, message=nil) #:nodoc:
      message = message << " " unless message.nil?
      ": #{message}(FileMaker Error ##{code})"
    end
    
    def self.find_error_by_code(code) #:nodoc:
      case code
      when 0..99
        SystemError
      when 100..199
        if code == 101; RecordMissingError
        elsif code == 102; FieldMissingError
        elsif code == 104; ScriptMissingError
        elsif code == 105; LayoutMissingError
        elsif code == 106; TableMissingError
        else; MissingError; end
      when 203..299
        if code == 200; RecordAccessDeniedError
        elsif code == 201; FieldCannotBeModifiedError
        elsif code == 202; FieldAccessIsDeniedError
        else; SecurityError; end
      when 300..399
        if code == 301; RecordInUseError
        elsif code == 302; TableInUseError
        elsif code == 306; RecordModIdDoesNotMatchError
        else; ConcurrencyError; end
      when 400..499
       if code == 401; NoRecordsFoundError
       else; GeneralError; end
      when 500..599
        if code == 500; DateValidationError
        elsif code == 501; TimeValidationError
        elsif code == 502; NumberValidationError
        elsif code == 503; RangeValidationError
        elsif code == 504; UniqueValidationError
        elsif code == 505; ExistingValidationError
        elsif code == 506; ValueListValidationError
        elsif code == 507; ValidationCalculationError
        elsif code == 508; InvalidFindModeValueError
        elsif code == 511; MaximumCharactersValidationError
        else; ValidationError
        end
      when 800..899
        if code == 802; UnableToOpenFileError
        else; FileError; end
      else
        UnknownError
      end
    end
    
    def self.instantiate_error(klass, message) #:nodoc:
      klass.new("#{klass.to_s.gsub(/Rfm::/, '')} occurred#{message}")
    end
  end
  
  class UnknownError < FileMakerError #:nodoc:
  end
  
  class SystemError < FileMakerError #:nodoc:
  end
  
  class MissingError < FileMakerError  #:nodoc:
  end
  
  class RecordMissingError < MissingError #:nodoc:
  end

  class FieldMissingError < MissingError #:nodoc:
  end

  class ScriptMissingError < MissingError #:nodoc: 
  end

  class LayoutMissingError < MissingError #:nodoc: 
  end

  class TableMissingError < MissingError #:nodoc:
  end

  class SecurityError < FileMakerError #:nodoc:
  end
  
  class RecordAccessDeniedError < SecurityError #:nodoc:
  end

  class FieldCannotBeModifiedError < SecurityError #:nodoc:
  end

  class FieldAccessIsDeniedError < SecurityError #:nodoc:
  end
  
  class ConcurrencyError < FileMakerError #:nodoc:
  end
  
  class RecordInUseError < ConcurrencyError #:nodoc:
  end

  class TableInUseError < ConcurrencyError #:nodoc:
  end

  class RecordModIdDoesNotMatchError < ConcurrencyError #:nodoc:
  end

  class GeneralError < FileMakerError #:nodoc:
  end

  class NoRecordsFoundError < GeneralError #:nodoc:
  end
   
  class ValidationError < FileMakerError #:nodoc:
  end 

  class DateValidationError < ValidationError #:nodoc:
  end

  class TimeValidationError < ValidationError #:nodoc:
  end
  
  class NumberValidationError < ValidationError #:nodoc: 
  end
  
  class RangeValidationError < ValidationError #:nodoc:
  end

  class UniqueValidationError < ValidationError #:nodoc:
  end
  
  class ExistingValidationError < ValidationError #:nodoc:
  end

  class ValueListValidationError < ValidationError #:nodoc:
  end

  class ValidationCalculationError < ValidationError #:nodoc:
  end

  class InvalidFindModeValueError < ValidationError #:nodoc:
  end

  class MaximumCharactersValidationError < ValidationError #:nodoc:
  end

  class FileError < FileMakerError #:nodoc:
  end 

  class UnableToOpenFileError < FileError #:nodoc:
  end
end