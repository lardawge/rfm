require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Rfm
  describe FileMakerError, ".get" do
    
    it "should return a default system error if input code is 0" do
      error = FileMakerError.get(0)
      error.message.should eql('SystemError occurred: (FileMaker Error #0)')
      error.code.should eql(0)
    end
    
    it "should return a custom message as second argument" do
      error = FileMakerError.get(104, 'Custom Message Here.')
      error.message.should match(/Custom Message Here/)
    end

    it "should return a script missing error" do
      error = FileMakerError.get(104)
      error.message.should eql('ScriptMissingError occurred: (FileMaker Error #104)')
      error.code.should eql(104)
    end  
    
    it "should return a range validation error" do
      error = FileMakerError.get(503)
      error.message.should eql('RangeValidationError occurred: (FileMaker Error #503)')
      error.code.should eql(503)
    end  
    
    it "should return unknown error if code not found" do
      error = FileMakerError.get(-1)
      error.message.should eql('UnknownError occurred: (FileMaker Error #-1)')
      error.code.should eql(-1)
    end
    
  end
end
