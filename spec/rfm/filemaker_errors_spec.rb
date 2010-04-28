require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Rfm
  err_module = FilemakerError
  describe err_module do
    describe ".get" do
      
      it "should return a default system error if input code is 0" do
        error = err_module.get(0)
        error.message.should eql('SystemError occurred: (FileMaker Error #0)')
        error.code.should eql(0)
      end
      
      it "should return a custom message as second argument" do
        error = err_module.get(104, 'Custom Message Here.')
        error.message.should match(/Custom Message Here/)
      end
    
      it "should return a script missing error" do
        error = err_module.get(104)
        error.message.should eql('ScriptMissingError occurred: (FileMaker Error #104)')
        error.code.should eql(104)
      end  
      
      it "should return a range validation error" do
        error = err_module.get(503)
        error.message.should eql('RangeValidationError occurred: (FileMaker Error #503)')
        error.code.should eql(503)
      end  
      
      it "should return unknown error if code not found" do
        error = err_module.get(-1)
        error.message.should eql('UnknownError occurred: (FileMaker Error #-1)')
        error.code.should eql(-1)
        #error.class.should eql(UnknownError)
      end
      
    end
    
    describe ".instantiate_error" do
      it "should create a class based on the constant recieved" do
        error = err_module.instantiate_klass(Unknown)
        error.class.should eql(Unknown)
      end
    end
    
    describe ".find_by_code" do
      it "should return a constant representing the error class" do
        constant = err_module.find_by_code(503)
        constant.should eql(RangeValidation)
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
        @message.should eql('503Error occurred: (FileMaker Error #This is a custom message)')
      end
    end
    
  end
end
