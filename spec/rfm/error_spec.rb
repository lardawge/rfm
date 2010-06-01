require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Rfm
  err_module = Error
  describe err_module do
    describe ".lookup" do
      
      it "should return a default system error if input code is 0" do
        error = err_module.getError(0)
        error.message.should eql('SystemError occurred: (FileMaker Error #0)')
        error.code.should eql(0)
      end
      
      it "should return a default system error if input code is 22" do
        error = err_module.getError(20)
        error.message.should eql('SystemError occurred: (FileMaker Error #20)')
        error.code.should eql(20)
      end
      
      it "should return a custom message as second argument" do
        error = err_module.getError(104, 'Custom Message Here.')
        error.message.should match(/Custom Message Here/)
      end
    
      it "should return a script missing error" do
        error = err_module.getError(104)
        error.message.should eql('ScriptMissingError occurred: (FileMaker Error #104)')
        error.code.should eql(104)
      end  
      
      it "should return a range validation error" do
        error = err_module.getError(503)
        error.message.should eql('RangeValidationError occurred: (FileMaker Error #503)')
        error.code.should eql(503)
      end  
      
      it "should return unknown error if code not found" do
        error = err_module.getError(-1)
        error.message.should eql('UnknownError occurred: (FileMaker Error #-1)')
        error.code.should eql(-1)
        error.class.should eql(Error::UnknownError)
      end
      
    end
    
    describe ".find_by_code" do
      it "should return a constant representing the error class" do
        constant = err_module.find_by_code(503)
        constant.should eql(err_module::RangeValidationError)
      end
    end
    
    describe ".build_message" do
      before(:each) do
        @message = err_module.build_message(503, 'This is a custom message')
      end
      
      it "should return a string with the code and message included" do
        @message.should match(/This is a custom message/)
        @message.should match(/503/)
      end
      
      it "should look like" do
        @message.should eql('503 occurred: (FileMaker Error #This is a custom message)')
      end
    end
    
  end
end
