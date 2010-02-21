require 'spec_helper'

module Rfm::Error
  describe FileMakerError, ".get_error" do
    
    it "should return a default system error if input code is 0" do
      error = Rfm::Error::FileMakerError.get_error(0)
      error.message.should eql('SystemError occurred: (FileMaker Error #0)')
      error.code.should eql(0)
    end
    
    it "should return a custom message as secod argument" do
      error = Rfm::Error::FileMakerError.get_error(104, 'Custom Message Here.')
      error.message.should match(/Custom Message Here/)
    end

    it "should return a script missing error" do
      error = Rfm::Error::FileMakerError.get_error(104)
      error.message.should eql('ScriptMissingError occurred: (FileMaker Error #104)')
      error.code.should eql(104)
    end  
    
    it "should return a range validation error" do
      error = Rfm::Error::FileMakerError.get_error(503)
      error.message.should eql('RangeValidationError occurred: (FileMaker Error #503)')
      error.code.should eql(503)
    end  
    
    it "should return unknown error if code not found" do
      error = Rfm::Error::FileMakerError.get_error(-1)
      error.message.should eql('UnknownError occurred: (FileMaker Error #-1)')
      error.code.should eql(-1)
    end
    
  end
end
