class TwilioController < ApplicationController
  layout "twilio.layout"
  respond_to :xml
  
  def testaction    
    @digits = params[:Digits]
  end    
end