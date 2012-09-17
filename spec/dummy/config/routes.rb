Dummy::Application.routes.draw do
  resources :twilio do
    post "teststart", :on => :collection
    post "testaction", :on => :collection
        
    post "testhangup", :on => :collection
    post "testdial", :on => :collection
    post "testredirect", :on => :collection
    post "testsay", :on => :collection
  end  
end
