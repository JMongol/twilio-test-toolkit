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

      return CallScope.from_post(self, el.text)
    end

    def follow_redirect!
      el = get_redirect_node
      raise "No redirect" if el.nil?

      post_for_twiml!(normalize_redirect_path(el.text))
    end

    # Stuff for Says
    def has_say?(say)
      @xml.xpath("Say").each do |s|
        return true if s.inner_text.include?(say)
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
      rasie "Not a gather" unless gather?
      return @xml["action"]
    end

    def press(digits)
      raise "Not a gather" unless gather?

      # Fetch the path and then post
      path = gather_action

      # Update the root call
      root_call.post_for_twiml!(path, digits)
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

      # Create a new object from a post
      def self.from_post(parent, path, digits = "")
        new_scope = CallScope.new
        new_scope.send(:root_call=, parent.root_call)
        new_scope.send(:post_for_twiml!, path, digits)
        return new_scope
      end

      def normalize_redirect_path(path)
        p = path

        # Strip off ".xml" off of the end of any path
        p = path[0...path.length - ".xml".length] if path.downcase.ends_with?(".xml")
        return p
      end

      # Post and update the scope
      def post_for_twiml!(path, digits = "", is_machine = false)
        @current_path = normalize_redirect_path(path)

        # Post the query
        rack_test_session_wrapper = Capybara.current_session.driver      
        @response = rack_test_session_wrapper.post(@current_path, 
          :format => :xml, 
          :CallSid => @sid, 
          :Digits => digits, 
          :From => @from_number, 
          :To => @to_number,
          :AnsweredBy => (is_machine ? "machine" : "human")
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