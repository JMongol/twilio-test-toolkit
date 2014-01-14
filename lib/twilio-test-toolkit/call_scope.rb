module TwilioTestToolkit
  # Models a scope within a call.
  class CallScope

    # Note that el is case sensitive and must match the desired
    # TwiML element. eg. Play (correct) vs play (incorrect).
    def self.has_element(el, options = {})
      define_method "has_#{el.downcase}?" do |inner = nil|
        return has_element?(el, inner, options)
      end
    end

    # method_missing? will take care of most cases, but for elements
    # where the preference is to have exact matching, just add a
    # definition like:
    #
    # has_element "Foo", :exact_inner_match => true
    has_element "Play", :exact_inner_match => true

    # Stuff for redirects
    def has_redirect_to?(url)
      el = get_redirect_node
      return false if el.nil?
      return normalize_redirect_path(el.text) == normalize_redirect_path(url)
    end

    def follow_redirect(options = {})
      el = get_redirect_node
      raise "No redirect" if el.nil?

      return CallScope.from_request(self, el.text, { :method =>el[:method]}.merge(options))
    end

    def follow_redirect!(options = {})
      el = get_redirect_node
      raise "No redirect" if el.nil?

      request_for_twiml!(normalize_redirect_path(el.text), { :method => el[:method] }.merge(options))
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
      return @xml["finishOnKey"] || '#' # '#' is the default finish key if not specified
    end

    def press(digits)
      raise "Not a gather" unless gather?

      # Fetch the path and then post
      path = gather_action

      # Update the root call
      root_call.request_for_twiml!(path, :digits => digits, :method => gather_method, :finish_on_key => gather_finish_on_key)
    end

    # Make this easier to support TwiML elements...
    def method_missing(meth, *args, &block)
      # support any check for a given attribute on a given element
      #
      # eg. has_action_on_dial?, has_method_on_sip?, etc.
      #
      # Attribute-checking appears to be case-sensitive, which x means:
      #
      # has_finishOnKey_on_record?("#")
      #
      # I'm not crazy about this mixed case, so we can also do a more
      # Rubyish way:
      #
      # has_finish_on_key_on_record?("#")
      #
      if meth.to_s =~ /^has_([a-zA-Z_]+)_on_([a-zA-Z]+)\?$/
        has_attr_on_element?($2, $1, *args, &block)

      # support any check for the existence of a given element
      # with an optional check on the inner_text.
      elsif meth.to_s =~ /^has_([a-zA-Z]+)\?$/
        has_element?($1, *args, &block)

      # get a given element node
      elsif meth.to_s =~ /^get_([a-z]+)_node$/
        get_element_node($1, *args, &block)

      # run a block within a given node context
      elsif meth.to_s =~ /^within_([a-z]+)$/
        within_element($1, *args, &block)

      else
        super # You *must* call super if you don't handle the
              # method, otherwise you'll mess up Ruby's method
              # lookup.
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.match(/^(has_|get_[a-z]+_node|within_)/) || super
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
      def formatted_digits(digits, options = {})
        if digits.nil?
          ''
        elsif options[:finish_on_key]
          digits.to_s.split(options[:finish_on_key])[0]
        else
          digits
        end
      end

      def get_element_node(el)
        el[0] = el[0,1].upcase
        @xml.at_xpath(el)
      end

      # Within element returns a scope that's tied to the specified element
      def within_element(el, &block)
        element_node = get_element_node(el)

        raise "No el in scope" if element_node.nil?
        yield(CallScope.from_xml(self, element_node))
      end

      def has_attr_on_element?(el, attr, value)
        el[0] = el[0,1].upcase
        # convert snake case to lower camelCase
        if attr.match(/_/)
          attr = camel_case_lower(attr)
        end

        attr_on_el = @xml.xpath(el).attribute(attr)
        !!attr_on_el && attr_on_el.value == value
      end

      def has_element?(el, inner = nil, options = {})
        el[0] = el[0,1].upcase
        return !(@xml.at_xpath(el).nil?) if inner.nil?

        @xml.xpath(el).each do |s|
          if !options[:exact_inner_match].nil? && options[:exact_inner_match] == true
            return true if s.inner_text.strip == inner
          else
            return true if s.inner_text.include?(inner)
          end
        end

        return false
      end

      def camel_case_lower(subject)
        subject.split('_').inject([]){ |buffer,e| buffer.push(buffer.empty? ? e : e.capitalize) }.join
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
        new_scope.send(:request_for_twiml!, path, options)
        return new_scope
      end

      def normalize_redirect_path(path)
        p = path

        # Strip off ".xml" off of the end of any path
        p = path[0...path.length - ".xml".length] if path.downcase.match(/\.xml$/)
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
          :Digits => formatted_digits(options[:digits].to_s, :finish_on_key => options[:finish_on_key]),
          :To => @root_call.to_number,
          :AnsweredBy => (options[:is_machine] ? "machine" : "human"),
          :CallStatus => options.fetch(:call_status, "in-progress")
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
