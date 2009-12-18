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
      
      # Default filemaker error message map
      @default_messages = {}
      class << self; attr_reader :default_messages; end
      
      
      # This method instantiates and returns the appropriate FileMakerError object depending on the error code passed to it. It
      # also accepts an optional message.
      def self.getError(code, message = nil)
        if @default_messages == nil or @default_messages.size == 0
          (0..99).each{|i| @default_messages[i] = 'SystemError occurred.'}
          (100..199).each{|i| @default_messages[i] = 'MissingError occurred.'}
          @default_messages[102] = 'FieldMissingError occurred.'
          @default_messages[104] = 'ScriptMissingError occurred.'
          @default_messages[105] = 'LayoutMissingError occurred.'
          @default_messages[106] = 'TableMissingError occurred.'
          (200..299).each{|i| @default_messages[i] = 'SecurityError occurred.'}
          @default_messages[200] = 'RecordAccessDeniedError occurred.'
          @default_messages[201] = 'FieldCannotBeModifiedError occurred.'
          @default_messages[202] = 'FieldAccessIsDeniedError occurred.'
          (300..399).each{|i| @default_messages[i] = 'ConcurrencyError occurred.'}
          @default_messages[301] = 'RecordInUseError occurred.'
          @default_messages[302] = 'TableInUseError occurred.'
          @default_messages[306] = 'RecordModIdDoesNotMatchError occurred.'
          (400..499).each{|i| @default_messages[i] = 'GeneralError occurred.'}
          @default_messages[401] = 'NoRecordsFoundError occurred.'
          (500..599).each{|i| @default_messages[i] = 'ValidationError occurred.'}
          @default_messages[500] = 'DateValidationError occurred.'
          @default_messages[501] = 'TimeValidationError occurred.'
          @default_messages[502] = 'NumberValidationError occurred.'
          @default_messages[503] = 'RangeValidationError occurred.'
          @default_messages[504] = 'UniqueValidationError occurred.'
          @default_messages[505] = 'ExistingValidationError occurred.'
          @default_messages[506] = 'ValueListValidationError occurred.'
          @default_messages[507] = 'ValidationCalculationError occurred.'
          @default_messages[508] = 'InvalidFindModeValueError occurred.'
          @default_messages[511] = 'MaximumCharactersValidationError occurred.'
          (800..899).each{|i| @default_messages[i] = 'FileError occurred.'}
          @default_messages[802] = 'UnableToOpenFileError occurred.'
        end 
        
        message = @default_messages[code] if message == nil || message.strip == ''
        message += " (FileMaker Error ##{code})"
        
        if 0 <= code and code <= 99
          err = SystemError.new(message)
        elsif 100 <= code and code <= 199
          if code == 101
            err = RecordMissingError.new(message)
          elsif code == 102
            err = FieldMissingError.new(message)
          elsif code == 104
            err = ScriptMissingError.new(message)
          elsif code == 105
            err = LayoutMissingError.new(message)
          elsif code == 106
            err = TableMissingError.new(message)
          else
            err = MissingError.new(message)
          end
        elsif 200 <= code and code <= 299
          if code == 200
            err = RecordAccessDeniedError.new(message)
          elsif code == 201
            err = FieldCannotBeModifiedError.new(message)
          elsif code == 202
            err = FieldAccessIsDeniedError.new(message)
          else
            err = SecurityError.new(message)
          end
        elsif 300 <= code and code <= 399
          if code == 301
            err = RecordInUseError.new(message)
          elsif code == 302
            err = TableInUseError.new(message)
          elsif code == 306
            err = RecordModIdDoesNotMatchError.new(message)
          else
            err = ConcurrencyError.new(message)
          end
        elsif 400 <= code and code <= 499
          if code == 401
            err = NoRecordsFoundError.new(message)
          else
            err = GeneralError.new(message)
          end
        elsif 500 <= code and code <= 599
          if code == 500
            err = DateValidationError.new(message)
          elsif code == 501
            err = TimeValidationError.new(message)
          elsif code == 502
            err = NumberValidationError.new(message)
          elsif code == 503
            err = RangeValidationError.new(message)
          elsif code == 504
            err = UniqueValidationError.new(message)
          elsif code == 505
            err = ExistingValidationError.new(message)
          elsif code == 506
            err = ValueListValidationError.new(message)
          elsif code == 507
            err = ValidationCalculationError.new(message)
          elsif code == 508
            err = InvalidFindModeValueError.new(message)
          elsif code == 511
            err = MaximumCharactersValidationError.new(message)
          else
            err = ValidationError.new(message)
          end
        elsif 800 <= code and code <= 899
          if code == 802
            err = UnableToOpenFileError.new(message)
          else
            err = FileError.new(message)
          end
        else 
          # called for code == -1 or any other code not handled above.
          err = UnknownError.new(message)
        end
        err.code = code
        return err
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