require "twilio-test-toolkit/call_scope"
  
module TwilioTestToolkit
  # Models a call
  class CallInProgress < CallScope
    # Init the call
    def initialize(initial_path, from_number, to_number, call_sid, is_machine)
      # Save our variables for later
      @initial_path = initial_path
      @from_number = from_number
      @to_number = to_number
      @is_machine = is_machine

      # Generate an initial call SID if we don't have one
      if (call_sid.nil?)
        @sid = UUIDTools::UUID.random_create.to_s
      else
        @sid = call_sid
      end

      # We are the root call
      self.root_call = self

      # Create the request
      post_for_twiml!(@initial_path, "", @is_machine)
    end

    def sid
      @sid
    end      
  
    def initial_path
      @initial_path
    end
  
    def from_number
      @from_number
    end
  
    def to_number
      @to_number
    end
  
    def is_machine
      @is_machine
    end
  end
end