module TwilioTestToolkit
  require 'twilio-test-toolkit/call_in_progress'
  
  # Adds the `ttt_call` method to the top-level namespace.
  module DSL            
    #     call = ttt_call(inbound_phone_index_path, "+12065551212")
    def ttt_call(initial_path, from_number, to_number, call_sid = nil, is_machine = false)
      # Make a new call in progress
      return CallInProgress.new(initial_path, from_number, to_number, call_sid, is_machine)        
    end
  end
end
