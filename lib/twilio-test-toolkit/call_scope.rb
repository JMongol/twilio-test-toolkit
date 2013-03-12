module TwilioTestToolkit
  # Models a scope within a call.
  class CallScope    
    # Stuff for redirects
    def has_redirect_to?(url)
      el = get_redirect_node
      return false if el.nil?
      return normalize_redirect_path(el.text) == normalize_redirect_path(url)
    end

    def follow_redirect
      el = get_redirect_node
      raise "No redirect" if el.nil?

      return CallScope.from_request(self, el.text, :method =>el[:method])
    end

    def follow_redirect!
      el = get_redirect_node
      raise "No redirect" if el.nil?

      request_for_twiml!(normalize_redirect_path(el.text), :method => el[:method])
    end

    # Stuff for Says
    def has_say?(say)
      @xml.xpath("Say").each do |s|
        return true if s.inner_text.include?(say)
      end

      return false
    end

    # Stuff for Plays
    def has_play?(play)
      @xml.xpath("Play").each do |s|
        return true if s.inner_text == play
      end

      return false
    end

    # Stuff for Dials
    def has_dial?(number)
      @xml.xpath("Dial").each do |s|
        return true if s.inner_text.include?(number)
      end

      return false
    end

    # Stuff for hangups
    def has_redirect?
      return !(@xml.at_xpath("Redirect").nil?)
    end

    def has_hangup?
      return !(@xml.at_xpath("Hangup").nil?)
    end

    def has_gather?
      return !(@xml.at_xpath("Gather").nil?)
    end

    # Within gather returns a scope that's tied to the specified gather.
    def within_gather(&block)
      gather_el = get_gather_node
      raise "No gather in scope" if gather_el.nil?
      yield(CallScope.from_xml(self, gather_el))
    end

    # Stuff for gatherers
    def gather?
      @xml.name == "Gather"
    end
    
    def gather_action
      raise "Not a gather" unless gather?
      return @xml["action"]
    end

    def gather_method
      raise "Not a gather" unless gather?
      return @xml["method"]
    end

    def gather_finish_on_key
      raise "Not a gather" unless gather?
      return @xml["finishOnKey"]
    end

    def press(digits)
      raise "Not a gather" unless gather?

      # Fetch the path and then post
      path = gather_action

      # Update the root call
      root_call.request_for_twiml!(path, :digits => digits, :method => gather_method)
    end

    # Some basic accessors
    def current_path
      @current_path
    end

    def response_xml
      @response_xml
    end

    def root_call
      @root_call
    end

    private
      def get_redirect_node
        @xml.at_xpath("Redirect")      
      end

      def get_gather_node
        @xml.at_xpath("Gather")      
      end

      def formatted_digits(digits, options = {})
        if digits.nil?
          ''
        elsif options[:finish_on_key]
          digits.split(options[:finish_on_key])[0]
        else
          digits
        end
      end

    protected
      # New object creation
      def self.from_xml(parent, xml)
        new_scope = CallScope.new
        new_scope.send(:set_xml, xml)
        new_scope.send(:root_call=, parent.root_call)
        return new_scope
      end

      def set_xml(xml)
        @xml = xml
      end

      # Create a new object from a post. Options:
      # * :method - the http method of the request, defaults to :post
      # * :digits - becomes params[:Digits], defaults to ""
      def self.from_request(parent, path, options = {})
        new_scope = CallScope.new
        new_scope.send(:root_call=, parent.root_call)
        new_scope.send(:request_for_twiml!, path, :digits => options[:digits] || "", :method => options[:method] || :post)
        return new_scope
      end

      def normalize_redirect_path(path)
        p = path

        # Strip off ".xml" off of the end of any path
        p = path[0...path.length - ".xml".length] if path.downcase.ends_with?(".xml")
        return p
      end

      # Post and update the scope. Options:
      # :digits - becomes params[:Digits], optional (becomes "")
      # :is_machine - becomes params[:AnsweredBy], defaults to false / human
      def request_for_twiml!(path, options = {})
        @current_path = normalize_redirect_path(path)

        # Post the query
        rack_test_session_wrapper = Capybara.current_session.driver      
        @response = rack_test_session_wrapper.send(options[:method] || :post, @current_path,
          :format => :xml, 
          :CallSid => @root_call.sid, 
          :From => @root_call.from_number, 
          :Digits => formatted_digits(options[:digits], :finish_on_key => options[:finish_on_key]),
          :To => @root_call.to_number,
          :AnsweredBy => (options[:is_machine] ? "machine" : "human")
        )

        # All Twilio responses must be a success.
        raise "Bad response: #{@response.status}" unless @response.status == 200        

        # Load the xml
        data = @response.body
        @response_xml = Nokogiri::XML.parse(data)      
        set_xml(@response_xml.at_xpath("Response"))
      end

      # Parent call control
      def root_call=(val)
        @root_call = val
      end
  end
end