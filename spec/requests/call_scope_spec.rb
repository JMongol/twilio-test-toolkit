require 'spec_helper'

describe TwilioTestToolkit::CallScope do
  before(:each) do
    @our_number = "2065551212"
    @their_number = "2065553434"             
  end
  
  describe "basics" do
    before(:each) do
      @call = ttt_call(test_start_twilio_index_path, @our_number, @their_number)
    end
    
    it "should be a CallScope" do
      @call.should be_a(TwilioTestToolkit::CallScope)
    end
    
    it "should have the informational methods" do
      @call.should respond_to(:current_path)
      @call.should respond_to(:response_xml)
    end
    
    it "should have the right path" do
      @call.current_path.should == test_start_twilio_index_path
    end
    
    it "should have a response xml value" do
      @call.response_xml.should_not be_blank
    end
    
    it "should have the right root call" do
      @call.should respond_to(:root_call)
      @call.root_call.should == @call
    end
  end
  
  describe "redirect" do
    describe "success" do
      before(:each) do
        @call = ttt_call(test_redirect_twilio_index_path, @our_number, @their_number)
      end
    
      it "should have the redirect methods" do
        @call.should respond_to(:has_redirect?)
        @call.should respond_to(:has_redirect_to?)
        @call.should respond_to(:follow_redirect)
        @call.should respond_to(:follow_redirect!)
      end
    
      it "should have the right value for has_redirect?" do
        @call.should have_redirect
      end
    
      it "should have the right values for has_redirect_to?" do
        @call.has_redirect_to?("http://foo").should be_false
        @call.has_redirect_to?(test_start_twilio_index_path).should be_true
        @call.has_redirect_to?(test_start_twilio_index_path + ".xml").should be_true    # Should force normalization
      end
      
      it "should follow the redirect (immutable version)" do
        # follow_redirect returns a new CallScope
        newcall = @call.follow_redirect
        
        # Make sure it followed
        newcall.current_path.should == test_start_twilio_index_path
        
        # And is not the same call
        newcall.response_xml.should_not == @call.response_xml
        # But it's linked
        newcall.root_call.should == @call
        
        # And we did not modify the original call
        @call.current_path.should == test_redirect_twilio_index_path
      end
      
      it "should follow the redirect (mutable version)" do
        # follow_redirect! modifies the CallScope
        @call.follow_redirect!
        
        # Make sure it followed
        @call.current_path.should == test_start_twilio_index_path
      end
    end
    
    describe "failure" do
      before(:each) do
        # Initiate a call that's not on a redirect - various calls will fail
        @call = ttt_call(test_say_twilio_index_path, @our_number, @their_number)
      end
      
      it "should have the right value for has_redirect?" do
        @call.should_not have_redirect
      end
      
      it "should have the right values for has_redirect_to?" do
        @call.has_redirect_to?("http://foo").should be_false
        @call.has_redirect_to?(test_start_twilio_index_path).should be_false
        @call.has_redirect_to?(test_start_twilio_index_path + ".xml").should be_false
      end
      
      it "should raise an error on follow_redirect" do
        lambda {@call.follow_redirect}.should raise_error
      end
      
      it "should raise an error on follow_redirect!" do
        lambda {@call.follow_redirect!}.should raise_error
      end
    end
  end
  
  describe "say" do
    before(:each) do
      @call = ttt_call(test_say_twilio_index_path, @our_number, @their_number)
    end
    
    it "should have the expected say methods" do
      @call.should respond_to(:has_say?)
    end
    
    it "should have the right values for has_say?" do
      @call.has_say?("Blah blah").should be_false
      @call.has_say?("This is a say page.").should be_true
      @call.has_say?("This is").should be_true      # Partial match
    end
  end
  
  describe "play" do
    before(:each) do
      @call = ttt_call(test_play_twilio_index_path, @our_number, @their_number)
    end

    it "should have the expected say play methods" do
      @call.should respond_to(:has_play?)
    end

    it "should have the right values for has_say?" do
      @call.has_play?("/path/to/a/different/audio/clip.mp3").should be_false
      @call.has_play?("/path/to/an/audio/clip.mp3").should be_true
      @call.has_play?("clip.mp3").should be_false
    end
  end

  describe "dial" do
    before(:each) do
      @call = ttt_call(test_dial_twilio_index_path, @our_number, @their_number)
    end

    it "should have the expected dial methods" do
      @call.should respond_to(:has_dial?)
    end

    it "should have the right values for has_dial?" do
      @call.has_dial?("911").should be_false
      @call.has_dial?("18001234567").should be_true
      @call.has_dial?("12345").should be_true     # Partial match
    end
  end
  
  describe "hangup" do
    describe "success" do
      before(:each) do
        @call = ttt_call(test_hangup_twilio_index_path, @our_number, @their_number)
      end

      it "should have the expected hangup methods" do
        @call.should respond_to(:has_hangup?)
      end
      
      it "should have the right value for has_hangup?" do
        @call.should have_hangup
      end
    end
    
    describe "failure" do
      before(:each) do
        @call = ttt_call(test_start_twilio_index_path, @our_number, @their_number)
      end

      it "should have the right value for has_hangup?" do
        @call.should_not have_hangup
      end
    end
  end
  
  describe "gather" do
    describe "success" do
      before(:each) do
        @call = ttt_call(test_start_twilio_index_path, @our_number, @their_number)
      end

      it "should have the expected gather methods" do
        @call.should respond_to(:has_gather?)
        @call.should respond_to(:within_gather)
        @call.should respond_to(:gather?)
        @call.should respond_to(:gather_action)
        @call.should respond_to(:press)
      end
      
      it "should have the right value for has_gather?" do
        @call.has_gather?.should be_true
      end
      
      it "should have the right value for gather?" do
        # Although we have a gather, the current call scope is not itself a gather, so this returns false.
        @call.gather?.should be_false
      end
      
      it "should fail on gather-scoped methods outside of a gather scope" do
        lambda {@call.gather_action}.should raise_error
        lambda {@call.press "1234"}.should raise_error
      end
      
      it "should gather" do
        # We should not have a say that's contained within a gather.
        @call.should_not have_say("Please enter some digits.")
        
        # Now enter the gather block.
        @call.within_gather do |gather|
          # We should have a say here
          gather.should have_say("Please enter some digits.")
          
          # We should be in a gather
          gather.gather?.should be_true
          # And we should have an action
          gather.gather_action.should == test_action_twilio_index_path
          
          # And we should have the right root call
          gather.root_call.should == @call
          
          # Press some digits.
          gather.press "98765"
        end
        
        # This should update the path
        @call.current_path.should == test_action_twilio_index_path
        
        # This view says the digits we pressed - make sure
        @call.should have_say "You entered 98765"
      end
      
      it "should gather without a press" do
        @call.within_gather do |gather|
          # Do nothing
        end
        
        # We should still be on the same page
        @call.current_path.should == test_start_twilio_index_path
      end
    end
    
    describe "failure" do
      before(:each) do
        @call = ttt_call(test_say_twilio_index_path, @our_number, @their_number)
      end
      
      it "should have the right value for has_gather?" do
        @call.has_gather?.should be_false
      end
      
      it "should have the right value for gather?" do
        @call.gather?.should be_false
      end
      
      it "should fail on within_gather if there is no gather" do
        lambda {@call.within_gather do |gather|; end}.should raise_error
      end
      
      it "should fail on gather-scoped methods outside of a gather scope" do
        lambda {@call.gather_action}.should raise_error
        lambda {@call.press "1234"}.should raise_error
      end
    end
  end
end