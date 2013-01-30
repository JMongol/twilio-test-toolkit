Dummy::Application.routes.draw do
  resources :twilio do
    post "test_start", :on => :collection
    post "test_action", :on => :collection
        
    post "test_hangup", :on => :collection
    post "test_dial", :on => :collection
    post "test_redirect", :on => :collection
    post "test_say", :on => :collection
  end  
end
