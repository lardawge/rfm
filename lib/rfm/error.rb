require "set"

# These classes wrap the filemaker error codes. FileMakerError is the base class of this hierarchy.
# 
# One could get a FileMakerError by doing:
#   err = Rfm::Error::FileMakerError.getError(102)
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
      def self.getError(code, message=nil)
        err = error_message(code)
        err.code = code
        return err
      end
      
      private
         
          def self.error_message(code)
            error_text = " (FileMaker Error ##{code})"
            case code
            when 0..99
              SystemError.new('SystemError occurred.' + error_text)
            when 100..199
              if 101; RecordMissingError.new('RecordMissingError occurred' + error_text)
              elsif 102; FieldMissingError.new('FieldMissingError occurred.' + error_text)
              elsif 104; ScriptMissingError.new('ScriptMissingError occurred.' + error_text)
              elsif 105; LayoutMissingError.new('LayoutMissingError occurred.' + error_text)
              elsif 106; TableMissingError.new('TableMissingError occurred.' + error_text)
              else; MissingError.new('MissingError occurred.' + error_text); end
            when 203..299
              if 200; RecordAccessDeniedError.new('RecordAccessDeniedError occurred.' + error_text)
              elsif 201; FieldCannotBeModifiedError.new('FieldCannotBeModifiedError occurred.' + error_text)
              elsif 202; FieldAccessIsDeniedError.new('FieldAccessIsDeniedError occurred.' + error_text)
              else; SecurityError.new('SecurityError occurred.' + error_text); end
            when 300..399
              if 301; RecordInUseError.new('RecordInUseError occurred.' + error_text)
              elsif 302; TableInUseError.new('TableInUseError occurred.' + error_text)
              elsif 306; RecordModIdDoesNotMatchError.new('RecordModIdDoesNotMatchError occurred.' + error_text)
              else; ConcurrencyError.new('ConcurrencyError occurred.' + error_text); end
            when 400..499
             if 401; NoRecordsFoundError.new('NoRecordsFoundError occurred.' + error_text)
             else; GeneralError.new('GeneralError occurred.' + error_text); end
            when 500..599
              if 500; DateValidationError.new('DateValidationError occurred.' + error_text)
              elsif 501; TimeValidationError.new('TimeValidationError occurred.' + error_text)
              elsif 502; NumberValidationError.new('NumberValidationError occurred.' + error_text)
              elsif 503; RangeValidationError.new('RangeValidationError occurred.'+ error_text)
              elsif 504; UniqueValidationError.new('UniqueValidationError occurred.' + error_text)
              elsif 505; ExistingValidationError.new('ExistingValidationError occurred.' + error_text)
              elsif 506; ValueListValidationError.new('ValueListValidationError occurred.' + error_text)
              elsif 507; ValidationCalculationError.new('ValidationCalculationError occurred.' + error_text)
              elsif 508; InvalidFindModeValueError.new('InvalidFindModeValueError occurred.' + error_text)
              elsif 511; MaximumCharactersValidationError.new('MaximumCharactersValidationError occurred.' + error_text)
              else; ValidationError.new('ValidationError occurred.' + error_text)
              end
            when 800..899
              if 802; UnableToOpenFileError.new('UnableToOpenFileError occurred.' + error_text)
              else; FileError.new('FileError occurred.' + error_text); end
            else
              UnknownError.new('UnknownError occured' + error_text)
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