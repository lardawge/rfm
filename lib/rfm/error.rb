require "set"

# These classes wrap the filemaker error codes. FileMakerError is the base class of this hierarchy.
# 
# One could get a FileMakerError by doing:
#   err = Rfm::Error::FileMakerError.get_error(102)
# 
# The above code would return a FieldMissingError instance. Your could use this instance to raise that appropriate
# exception:
# 
#   raise err 
# 
# You could access the specific error code by accessing:
#   
#   err.code
#   
# Author::    Mufaddal Khumri
# Copyright:: Copyright (c) 2007 Six Fried Rice, LLC and Mufaddal Khumri
# License::   See MIT-LICENSE for details
module Rfm
  module Error
    
    class RfmError < StandardError
    end
    
    class CommunicationError < RfmError
    end
    
    class ParameterError < RfmError
    end
    
    class AuthenticationError < RfmError
    end
    
    # Base class for all FileMaker errors
    class FileMakerError < RfmError
      attr_accessor :code
      
      # This method instantiates and returns the appropriate FileMakerError object depending on the error code passed to it. It
      # also accepts an optional message.
      def self.get_error(code, message=nil)
        message = message.nil? ? "(FileMaker Error ##{code})" : "#{message} (FileMaker Error ##{code})"
        error = error_message(code, message)
        error.code = code
        return error
      end
      
      # TODO Remove in next major release
      def self.getError(code, message=nil) #:nodoc:
        warn "The method get_error is deprecated and will be replaced by get_error."
        get_error(code, message)
      end
      
      private
         
          def self.error_message(code, error_message)
            case code
            when 0..99
              SystemError.new(error_message)
            when 100..199
              if 101; RecordMissingError.new(error_message)
              elsif 102; FieldMissingError.new(error_message)
              elsif 104; ScriptMissingError.new(error_message)
              elsif 105; LayoutMissingError.new(error_message)
              elsif 106; TableMissingError.new(error_message)
              else; MissingError.new(error_message); end
            when 203..299
              if 200; RecordAccessDeniedError.new(error_message)
              elsif 201; FieldCannotBeModifiedError.new(error_message)
              elsif 202; FieldAccessIsDeniedError.new(error_message)
              else; SecurityError.new(error_message); end
            when 300..399
              if 301; RecordInUseError.new(error_message)
              elsif 302; TableInUseError.new(error_message)
              elsif 306; RecordModIdDoesNotMatchError.new(error_message)
              else; ConcurrencyError.new(error_message); end
            when 400..499
             if 401; NoRecordsFoundError.new(error_message)
             else; GeneralError.new(error_message); end
            when 500..599
              if 500; DateValidationError.new(error_message)
              elsif 501; TimeValidationError.new(error_message)
              elsif 502; NumberValidationError.new(error_message)
              elsif 503; RangeValidationError.new(error_message)
              elsif 504; UniqueValidationError.new(error_message)
              elsif 505; ExistingValidationError.new(error_message)
              elsif 506; ValueListValidationError.new(error_message)
              elsif 507; ValidationCalculationError.new(error_message)
              elsif 508; InvalidFindModeValueError.new(error_message)
              elsif 511; MaximumCharactersValidationError.new(error_message)
              else; ValidationError.new(error_message)
              end
            when 800..899
              if 802; UnableToOpenFileError.new(error_message)
              else; FileError.new(error_message); end
            else
              UnknownError.new(error_message)
            end
          end
    end
    
    class UnknownError < FileMakerError  
    end
    
    class SystemError < FileMakerError  
    end
    
    class MissingError < FileMakerError  
    end
    
    class RecordMissingError < MissingError  
    end
  
    class FieldMissingError < MissingError  
    end
  
    class ScriptMissingError < MissingError  
    end
  
    class LayoutMissingError < MissingError  
    end
  
    class TableMissingError < MissingError  
    end
  
    class SecurityError < FileMakerError  
    end
    
    class RecordAccessDeniedError < SecurityError  
    end
  
    class FieldCannotBeModifiedError < SecurityError  
    end
  
    class FieldAccessIsDeniedError < SecurityError  
    end
    
    class ConcurrencyError < FileMakerError  
    end
    
    class RecordInUseError < ConcurrencyError  
    end
  
    class TableInUseError < ConcurrencyError  
    end
  
    class RecordModIdDoesNotMatchError < ConcurrencyError  
    end
  
    class GeneralError < FileMakerError  
    end
  
    class NoRecordsFoundError < GeneralError  
    end
     
    class ValidationError < FileMakerError  
    end 
  
    class DateValidationError < ValidationError  
    end
  
    class TimeValidationError < ValidationError  
    end
    
    class NumberValidationError < ValidationError  
    end
    
    class RangeValidationError < ValidationError  
    end
  
    class UniqueValidationError < ValidationError  
    end
    
    class ExistingValidationError < ValidationError  
    end
  
    class ValueListValidationError < ValidationError  
    end
  
    class ValidationCalculationError < ValidationError  
    end
  
    class InvalidFindModeValueError < ValidationError  
    end
  
    class MaximumCharactersValidationError < ValidationError  
    end
  
    class FileError < FileMakerError  
    end 
  
    class UnableToOpenFileError < FileError  
    end
  end
end