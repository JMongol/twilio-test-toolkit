twilio-test-toolkit
===================

Twilio Test Toolkit (TTT) makes RSpec integration tests for Twilio phone callbacks easy to write and understand.

When you initiate a [phone call with Twilio](http://www.twilio.com/docs/api/rest/making-calls), you must POST either a URL or an ApplicationSid that is configured with a URL. Twilio then POSTs to your URL, and you're expected to return a 200 OK and a valid [TwiML](http://www.twilio.com/docs/api/twiml) response. That response can be any valid TwiML - speak something, gather keystrokes, redirect, etc. 

Although it's pretty easy to test individual controller actions with the existing RSpec gem, testing more complex scenarios that use many controller actions (or controllers) is syntax-heavy and usually repetitive. TTT exists to make these larger scale integration tests easy and fun to write. TTT emulates the Twilio end of the Twilo phone callbacks, and allows to to emulate a user listening for a specific Say element, pressing keys on their phone, etc. With TTT, you can test your whole phone system built on Twilio.

For instance, let's say you have a controller that handles inbound Twilio calls and asks the user to enter an account number, then a PIN code, and then finally makes a menu selection. With TTT, you can just do this:

	@call = ttt_call(some_controller_action_path, from_number, to_number)
	
	@call.should have_say("Welcome to AwesomeCo.")
	@call.within_gather do |gather|
		gather.should have_say("Please enter your account number, followed by the pound sign.")
		gather.press "12345678"
	end
	
	@call.current_path.should == some_other_controller_action_path
	@call.within_gather do |gather|
		gather.should have_say("Please enter your 4 digit PIN code.")
		gather.press "9876"
	end
	
	@call.current_path.should == yet_another_controller_action_path
	@call.should have_say "Please choose from one of the following menu options"

TTT was originally built to handle testing a complex, large-scale phone tree system. Without TTT, it was necessary to do lots of deployments to staging to test how the controller actions worked together, and there wasn't a good automated way to verify any new changes. When new functionality was introduced, TTT tests were written for the full project, and everything that worked in TTT worked great the first time it was pushed to staging. It's a great timesaver.

What's supported
================

TTT supports most of the more common Twilio scenarios:

* Checking for Say elements and their content
* Taking action on Gather elements and querying their contents
* Following and querying redirects
* Dial and Hangup

TTT doesn't yet support (but you should contribute them!)

* Play
* Queue
* Any of the other conference calling features
	
What's required
================

TTT depends on [Capybara](https://github.com/jnicklas/capybara). It uses Capybara's session object to POST requests to your controllers. 

TTT expects your controller actions to behave like well-behaved Twilio callbacks. That is, you need to respond to XML-formatted requests, and need to respond with a 200 OK. TTT also requires that your controller actions be wired for POST, not GET (Twilio does support GET, but TTT lacks this support). Twilio will not follow 301 or 302 redirects properly, and neither will TTT (see below for more details). 

TTT has only been tested with RSpec on Rails. It might work on other test frameworks or other Rack-based frameworks. Feel free to submit pull requests to improve compatibility with these.

If it works with Twilio, it should work with TTT. If not, open an issue/pull request.

Getting started
================

First, get RSpec and Capybara working for your project. Then, you'll need to add this to your gemfile:

	group :test do
		...
		gem 'twilio-test-toolkit'
		...
	end

Since TTT is test-only code, it should be in the :test group.

You'll have to make one more change in spec/spec_helper.rb:

	RSpec.configure do |config|
		...
		# Configure Twilio Test Toolkit
	  	config.include TwilioTestToolkit::DSL, :type => :request
		...
	end

This line is required in order to get TTT's DSL to work with your tests.

Finally, since TTT deals with integration tests, you should write your tests in spec/requests (or whatever directory you've configured for this type of test).

How to use
================

This section describes how to use TTT and its basic functionality.

ttt_call
-------------

The *ttt_call* method is the main entry point for working with TTT. You call this method to initiate a "Twilio phone call" to your controller actions. TTT simulates Twilio's behavior by POSTing to your action with the expected Twilio parameters (From, To, CallSid, etc). 

*ttt_call* has three required parameters, and two optional ones:

	@call = ttt_call(action_path, from_number, to_number, call_sid = nil, is_machine = false)
	
* **action_path**. Where to POST your request. It should be obvious by now, but whatever action you specify here should be a POST action.
* **from_number**. What to fill params[:From] with. If you don't care about this value, you can pass a blank one, as this is only used to pass along to your actions.
* **to_number**. What to fill params[:To] with.
* **call_sid**. Specify an optional fixed value to be passed as params[:CallSid]. This is useful if you are expecting a specific SID. For instance, a common pattern is to initiate a call, store the SID in your database, and look up the call when you get the callback. If you don't pass a SID, TTT will generate one for you that's just a UUID.
* **is_machine**. Controls params[:AnsweredBy]. See Twilio's documentation for more information on how Twilio uses this.

*ttt_call* returns a *TwilioTestToolkit::CallInProgress* object, which is a descendent of *TwilioTestToolkit::CallScope*. You'll want to save this object as it's how you interact with TTT.

It's worth noting that TTT won't pass any of the parameters you need to [validate that a request comes from Twilio](http://www.twilio.com/docs/security). Most people seem to only do this check in production, so if that applies to you, this won't be an issue. If you do this check in dev and test, you might want to consider submitting a pull request with a fix.

Getting call information
--------------

You can use the CallInProgress object returned from *ttt_call* to inspect some basic properties about the call:

	@call.sid			# Returns the SID of the call
	@call.initial_path	# Returns the path that you used to start the call (the first parameter to ttt_call)
	@call.from_number	# Returns the from number
	@call.to_number		# Returns the to number
	@call.is_machine	# Returns the answering machine state (passed to ttt_call)

Call scopes
--------------

The CallInProgress object returned from *ttt_call* is a descendent of CallScope. A CallScope represents a scope within a call. For instance, the root TwiML Response element is a scope. A Gather within that is a scope. 
	
For instance, let's say you have TwiML like this:
	
	<Response>
		<Say>Foo</Say>
		<Gather action="baz">
			<Say>Bar</Say>
		</Gather>
	</Response>
	
The scope referred to by the CallInProgress object is the Response object. Only items that directly descend from this scope are seen by TTT. That is, the say for "Foo" is in the scope, but the say for "Bar" is not. The Gather is its own scope, and it contains the say for "Bar". TTT intentionally restricts you to accessing only what's in your scope because it helps you enforce a more rigid structure in your call, and allows you to handle multiple Gathers or similar in a given TwiML markup.

CallScope has some properties that are also useful:

	@call.current_path		# Returns the current path that the call is on.
	@call.response_xml		# Returns the raw XML response that your action returned to TTT
	@call.root_call			# Returns the original CallInProgress returned from ttt_call.

Inspecting the contents of the call
--------------

A common thing you'll want to do is inspect the various Say elements, and check for control elements like Dial and Hangup. 
	
	@call.has_say?("Foo")	# Returns true if there's a <Say> in the current scope 
							# that contains the text. Partial matches are OK, but 
							# the call is case sensitive.
	@call.has_dial?("911")	# Returns true if there's a <Dial> in the current scope 
							# for the number. Partial matches are OK.
	@call.has_hangup?		# Returns true if there's a <Hangup> in the current scope.
	
These methods are available on any CallScope.
	
Gathers
--------------

Gathers are used to collect digits from the caller (e.g. "press 1 to speak with a representative, press 2 to cancel"). Twilio handles Gathers by speaking the contents of the Gather and waiting for a digit or digits to be pressed. If nothing is pressed, it continues with the script. If something is pressed, it aborts processing the current script and POSTs the digits (via params[:Digits]) to the path specified by the action attribute. TTT handles Gathers in a similar way.

You can only interact with a gather by calling *within_gather*:

	@call.within_gather do |gather|
		gather.should have_say("Enter your account number")
		gather.press "12345"
	end

*within_gather* creates a new CallScope and passes it to the yielded parameter (gather in the example above). *within_gather* will fail if there is no Gather element in the current scope. 
	
You can verify the existence of a Gather in the current scope with:
	
	@call.has_gather?		# Returns true if the current scope has a gather.
	
Within a gather CallScope, you can use the following methods:
	
	@call.gather?			# Returns true if the current scope **is** a gather. Compare with the has_gather? method.
	@call.gather_action		# Returns the value of the action attribute for the gather.
	@call.press("1")		# Simulates pressing the specified digits.

You can also use other CallScope methods (e.g. *has_say?* and similar.)

The *press* method has a few caveats worth knowing. It's only callable once per gather - when you call it, TTT will immediately POST to the gather's action. There is no way to simulate pressing buttons slowly, and you don't really need to do this anyways - Twilio doesn't care and just passes them all at once. *press* simply fills out the value of params[:Digits] and POSTs that to your method, just like Twilio does.

Although you can technically pass whatever you want to *press*, in practice Twilio only sends digits and #. Still it's probably a good idea to test garbage data in this parameter with your actions, so TTT doesn't get in your way if you want to call press with "UNICORNSANDPONIES" as a parameter.

TTT doesn't attempt to validate your TwiML, so it's worth knowing that Gather only allows Say, Pause, and Play as child elements. Nested Gathers are not supported.
	
Redirects
--------------

The Redirect element is used to tell Twilio to POST to a different page. It differs from a standard 301 or 302 redirect (created by a *redirect_to*) in that the 301/302 redirects don't support a POST, and if you try a *redirect_to* within a Twilio action, Twilio will fail and your caller will get the dreaded "I'm sorry, an application error has occurred" message. Because Twilio doesn't support 301/302 redirects, TTT doesn't either, and if you use one, TTT will complain.
	
There are several methods you can use within a CallScope related to redirects:

	@call.has_redirect?					# Returns true if there's a <Redirect> element in the current scope.
	@call.has_redirect_to?(path)		# Returns true if there's a <Redirect> element to the specified path
	 									# in the current scope.
	@call.follow_redirect				# Follows the <Redirect> in the current scope and returns a new 
										# CallScope object. The original scope is not modified.
	@call.follow_redirect! 				# Follows the <Redirect> in the current scope and updates the scope 
										# to the new path. 
	
Although it's allowed by TwiML (as of this writing), multiple Redirects in a scope aren't effectively allowed, as only the first one will ever be used. Thus, TTT only looks at the first Redirect it finds in the given scope.
	
Contributing
================

TTT is pretty basic, but it should work for most people's needs. You might consider helping to improve it. Some things that could be done:

* Support more Twilio functionality
* Support GET actions. Twilio technically supports this, although it doesn't seem to be used very often.
* Build more stringent checks into says and plays - e.g. verify that there's enough of a pause between sentences.
* Build checks to make sure that numbers, dates, and other special text is spoken properly (e.g. "one two three" instead of "one hundred twenty three").
* Build checks to validate the correctness of your TwiML.
* Refactor wonky code (there's probably some in there somewhere)
* Write more tests. There are basic tests, but more involved ones might be nice
* Add support as needed for other test frameworks or Rack-based frameworks

Contributions are welcome and encouraged. The usual deal applies - fork a branch, add tests, add your changes, submit a pull request. If I haven't done anything with your pull request in a reasonable amount of time, ping me on Twitter or email and I'll get on it.

Running Tests
----------------

	bundle install
	cd spec/dummy
	bundle exec rake db:create
	cd ../..
	bundle exec rspec

Credits
================

TTT was put together by Jack Nichols [@jmongol](http://twitter.com/jmongol). MIT license.