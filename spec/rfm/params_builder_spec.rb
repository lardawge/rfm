require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Rfm
  builder = ParamsBuilder
  describe builder do
    
    describe ".parse" do
      it "should return an empty hash if no arguments sent" do
        params = builder.parse
        params.should be_empty
      end
      
      it "should return a hash with -db => name if Rfm db option set" do
        Rfm.options[:database] = 'data-base'
        params = builder.parse
        params.should == {"-db"=>"data-base"}
      end
      
      it "should return a hash with a blank value if no value entered" do
        Rfm.options[:database] = nil
        params = builder.parse(:edit)
        params['-edit'].should be_empty
      end
      
      it "should convert a symbol to string with a hyphen if not a hash" do
        Rfm.options[:database] = nil
        params = builder.parse(:edit)
        params.should have_key('-edit')
      end
      
      it "should return a hash if passed more than one hash" do
        params = builder.parse({:edit => true}, {:open => 'yes'})
        params.should have_key(:edit)
        params.should be_a Hash
      end
    end
    
    describe ".expand" do
      it "should return a hash with a nil value" do
        options = builder.expand('test')
        options.should be_a Hash
        options['test'].should be_nil
      end
      
      it "should return -max if :max_records" do
        options = builder.expand(:max_records => 10)
        options.should have_key('-max')
      end
      
      it "should return -skip if :skip_records" do
        options = builder.expand(:skip_records => 10)
        options.should have_key('-skip')
      end
      
      describe ":sort" do
        
        it "should return -sortfield.1 if :sort_field" do
          options = builder.expand(:sort_field => 'test')
          options.should have_key('-sortfield.1')
        end
        
        it "should return multiple -sortfield if :sort_field is an array" do
          options = builder.expand(:sort_field => ['test1', 'test2', 'test3'])
          i=0
          options.each do |key, value|
            key.should eql("-sortfield.#{i+=1}")
            value.should eql("test#{i}")
          end
        end

        it "should raise an exception if :sort_field has more than 9 arguments" do
          array = []; 10.times { |i| array << "test#{i}"}
          begin
            options = builder.expand(:sort_field => array)
          rescue ParameterError => error
            error.message.should eql(':sort_field can have at most 9 fields, but you passed an array with 10.')
          end
        end
        
        it "should return -sortorder.1 if :sort_order" do
          options = builder.expand(:sort_order => 'test')
          options.should have_key('-sortorder.1')
        end
        
        it "should return multiple -sortorder if :sort_order is an array" do
          options = builder.expand(:sort_order => ['test1', 'test2', 'test3']); i=0
          options.each do |key, value|
            key.should eql("-sortorder.#{i+=1}")
            value.should eql("test#{i}")
          end
        end

        it "should raise an exception if :sort_order has more than 9 arguments" do
          array = []; 10.times { |i| array << "test#{i}"}
          begin
            options = builder.expand(:sort_order => array)
          rescue ParameterError => error
            error.message.should eql(':sort_order can have at most 9 fields, but you passed an array with 10.')
          end
        end
      end
      
      
      
    end
  end
end