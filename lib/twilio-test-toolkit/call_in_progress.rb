require "twilio-test-toolkit/call_scope"
  
module TwilioTestToolkit
  # Models a call
  class CallInProgress < CallScope
    # Initiate a call. Options:
    # * :method - specify the http method of the initial api call
    # * :call_sid - specify an optional fixed value to be passed as params[:CallSid]
    # * :is_machine - controls params[:AnsweredBy]
    def initialize(initial_path, from_number, to_number, options = {})
      # Save our variables for later
      @initial_path = initial_path
      @from_number = from_number
      @to_number = to_number
      @is_machine = options[:is_machine]
      @method = options[:method] || :post

      # Generate an initial call SID if we don't have one
      if (options[:call_sid].nil?)
        @sid = UUIDTools::UUID.random_create.to_s
      else
        @sid = options[:call_sid]
      end

      # We are the root call
      self.root_call = self

      # Create the request
      request_for_twiml!(@initial_path, :method => @method, :is_machine => @is_machine)
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

    def method
      @method
    end
  end
end
