$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "twilio-test-toolkit/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "twilio-test-toolkit"
  s.version     = TwilioTestToolkit::VERSION
  s.authors     = ["Jack Nichols"]
  s.email       = ["jack@jmongol.com"]
  s.homepage    = "https://github.com/jmongol/twilio-test-toolkit"
  s.summary     = "Better integration tests for apps that use Twilio"
  s.description = "Better integration tests for apps that use Twilio"
  s.licenses = ["MIT"]
  
  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.require_paths = ["lib"]
  
  s.add_dependency 'capybara'
  s.add_dependency 'uuidtools'
  
  s.add_development_dependency "rails", "~> 3.2.12"
  s.add_development_dependency "sqlite3"  
  s.add_development_dependency "sqlite3-ruby"  
  s.add_development_dependency "rspec"  
  s.add_development_dependency "rspec-rails" 
  s.add_development_dependency "jquery-rails"
end

