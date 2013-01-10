Gem::Specification.new do |s|
  s.name        = 'mac_vendor'
  s.version     = '0.0.0'
  s.date        = '2013-01-09'
  s.license     = "MIT"
  s.summary     = "MAC address vendor lookup"
  s.description = "Given a MAC address, lookup the vendor of the interface."
  s.authors     = ["Doug Wiegley"]
  s.email       = 'doug@uceem.com'

  s.files         = `git ls-files`.split($/)
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']
  
  s.homepage    = 'https://github.com/uceem/mac_vendor.git'
end
