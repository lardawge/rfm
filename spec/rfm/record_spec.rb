require 'rfm/record'
describe Rfm::Record do
  describe "#[]=" do
    before(:each) do
      @record = Rfm::Record.allocate
      @record.instance_variable_set(:@mods, {})
      @record.instance_variable_set(:@loaded, false)
      @record['tester'] = 'red'
    end
    
    it "creates a new hash key => value upon instantiation of record" do
      @record.has_key?('tester').should be_true
      @record['tester'].should eql('red')
    end
    
    it "creates a new hash key => value in @mods when modifying an existing record key" do
      @record.instance_variable_set(:@loaded, true)
      @record['tester'] = 'green'
      
      @record.instance_variable_get(:@mods).has_key?('tester').should be_true
      @record.instance_variable_get(:@mods)['tester'].should eql('green')
    end
    
    it "raises an Rfm::ParameterError if a key is used that does not exist" do
      @record.instance_variable_set(:@loaded, true)
      
      ex = rescue_from { @record['tester2'] = 'error' }
      ex.class.should eql(Rfm::ParameterError)
      ex.message.should eql('You attempted to modify a field does not exist.')
    end
    
  end
  
  describe "#method_missing" do
    before(:each) do
      @record = Rfm::Record.allocate
      @record.instance_variable_set(:@mods, {})
      @record['name'] = 'red'
    end
    
    describe "getter" do
      it "will match a method to key in the hash if there is one" do
        @record.name.should eql('red')
      end

      it "will raise NoMethodError if no key present that matches value" do
        ex = rescue_from { @record.namee }
        ex.class.should eql(NoMethodError)
        ex.message.should match(/undefined method `namee'/)
      end
    end
    
    describe "setter" do
      it "acts as a setter if the key exists in the hash" do
        @record.name = 'blue'

        @record.instance_variable_get(:@mods).has_key?('name').should be_true
        @record.instance_variable_get(:@mods)['name'].should eql('blue')
      end
      
      it "will raise NoMethodError if no key present that matches value" do
        ex = rescue_from { @record.namee = 'red' }
        ex.class.should eql(NoMethodError)
        ex.message.should match(/undefined method `namee='/)
      end
    end

  end
end