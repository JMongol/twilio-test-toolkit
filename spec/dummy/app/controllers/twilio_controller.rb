class TwilioController < ApplicationController
  layout "twilio.layout"
  respond_to :xml
  
  def test_action
    @digits = params[:Digits]
  end    
end