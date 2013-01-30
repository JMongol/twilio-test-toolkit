module TwilioTestToolkit
  require 'twilio-test-toolkit/call_in_progress'
  
  # Adds the `ttt_call` method to the top-level namespace.
  module DSL
    # Initiate a call. Options:
    # * :method - specify the http method of the initial api call
    # * :call_sid - specify an optional fixed value to be passed as params[:CallSid]
    # * :is_machine - controls params[:AnsweredBy]
    def ttt_call(initial_path, from_number, to_number, options = {})
      # Make a new call in progress
      return CallInProgress.new(initial_path, from_number, to_number, options)
    end
  end
end
