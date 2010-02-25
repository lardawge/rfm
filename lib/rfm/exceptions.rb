module Rfm
  class RfmError < StandardError #:nodoc:
  end
  
  class CommunicationError < RfmError #:nodoc:
  end
  
  class ParameterError < RfmError #:nodoc:
  end
  
  class AuthenticationError < RfmError #:nodoc:
  end
  
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
    def self.get(code, error_message=nil)
      error = error_message(code, error_message)
      error.code = code
      return error
    end
    
    # TODO Remove in next major release
    def self.getError(code, message=nil) #:nodoc:
      warn "The #getError is deprecated and will be replaced by #get."
      get(code, message)
    end
    
    private
       
        def self.error_message(code, custom_message)
          message = custom_message.nil? ? "occurred: (FileMaker Error ##{code})" : "occured: #{custom_message} (FileMaker Error ##{code})"
          case code
          when 0..99
            SystemError.new("SystemError #{message}")
          when 100..199
            if code == 101; RecordMissingError.new("RecordMissingError #{message}")
            elsif code == 102; FieldMissingError.new("FieldMissingError #{message}")
            elsif code == 104; ScriptMissingError.new("ScriptMissingError #{message}")
            elsif code == 105; LayoutMissingError.new("LayoutMissingError #{message}")
            elsif code == 106; TableMissingError.new("TableMissingError #{message}")
            else; MissingError.new("MissingError #{message}"); end
          when 203..299
            if code == 200; RecordAccessDeniedError.new("RecordAccessDeniedError #{message}")
            elsif code == 201; FieldCannotBeModifiedError.new("FieldCannotBeModifiedError #{message}")
            elsif code == 202; FieldAccessIsDeniedError.new("FieldAccessIsDeniedError #{message}")
            else; SecurityError.new("SecurityError #{message}"); end
          when 300..399
            if code == 301; RecordInUseError.new("RecordInUseError #{message}")
            elsif code == 302; TableInUseError.new("TableInUseError #{message}")
            elsif code == 306; RecordModIdDoesNotMatchError.new("RecordModIdDoesNotMatchError #{message}")
            else; ConcurrencyError.new("ConcurrencyError #{message}"); end
          when 400..499
           if code == 401; NoRecordsFoundError.new("NoRecordsFoundError #{message}")
           else; GeneralError.new("GeneralError #{message}"); end
          when 500..599
            if code == 500; DateValidationError.new("DateValidationError #{message}")
            elsif code == 501; TimeValidationError.new("TimeValidationError #{message}")
            elsif code == 502; NumberValidationError.new("NumberValidationError #{message}")
            elsif code == 503; RangeValidationError.new("RangeValidationError #{message}")
            elsif code == 504; UniqueValidationError.new("UniqueValidationError #{message}")
            elsif code == 505; ExistingValidationError.new("ExistingValidationError #{message}")
            elsif code == 506; ValueListValidationError.new("ValueListValidationError #{message}")
            elsif code == 507; ValidationCalculationError.new("ValidationCalculationError #{message}")
            elsif code == 508; InvalidFindModeValueError.new("InvalidFindModeValueError #{message}")
            elsif code == 511; MaximumCharactersValidationError.new("MaximumCharactersValidationError #{message}")
            else; ValidationError.new("ValidationError #{message}")
            end
          when 800..899
            if code == 802; UnableToOpenFileError.new("UnableToOpenFileError #{message}")
            else; FileError.new("FileError #{message}"); end
          else
            UnknownError.new("UnknownError #{message}")
          end
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