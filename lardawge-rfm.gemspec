# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)
require "version"

Gem::Specification.new do |s|
  s.name        = "lardawge-rfm"
  s.version     = Rfm::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Geoff Coffey", "Mufaddal Khumri", "Atsushi Matsuo", "Larry Sprock"]
  s.email       = ["larry@lucidbleu.com"]
  s.homepage    = "https://github.com/lardawge/rfm"
  s.licenses    = ["MIT"]
  s.summary     = %q{Ruby to Filemaker adapter}
  s.description = %q{Rfm brings your FileMaker data to Ruby. Now your Ruby scripts and Rails applications can talk directly to your FileMaker server.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "nokogiri"
  s.add_dependency "addressable"

  s.add_development_dependency "rspec", ["~> 2.12.0"]
  s.add_development_dependency "mocha", ["~> 0.13.0"]
  s.add_development_dependency "rake"

end

