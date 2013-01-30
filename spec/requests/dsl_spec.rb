require 'spec_helper'

describe TwilioTestToolkit::DSL do
  before(:each) do
    @our_number = "2065551212"
    @their_number = "2065553434"        
  end
  
  describe "ttt_call" do
    describe "basics" do
      before(:each) do
        @call = ttt_call(test_start_twilio_index_path, @our_number, @their_number)
      end
    
      it "should assign the call" do
        @call.should_not be_nil
      end
    
      it "should have a sid" do
        @call.sid.should_not be_blank
      end
      
      it "should have the right properties" do
        @call.initial_path.should == test_start_twilio_index_path
        @call.from_number.should == @our_number
        @call.to_number.should == @their_number
        @call.is_machine.should be_false
      end      
    end
    
    describe "with a sid and machine override" do
      before(:each) do
        @mysid = "1234567"
        @call = ttt_call(test_start_twilio_index_path, @our_number, @their_number, @mysid, true)
      end
      
      it "should have the right sid" do
        @call.sid.should == @mysid
      end
      
      it "should be a machine call" do        
        @call.is_machine.should be_true
      end
    end
  end
end