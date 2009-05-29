# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rfm}
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Geoff Coffey", "Mufaddal Khumri", "Atsushi Matsuo", "Larry Sprock"]
  s.date = %q{2009-05-29}
  s.description = %q{Rfm brings your FileMaker data to Ruby with elegance and speed. Now your Ruby scripts and Rails applications can talk directly to your FileMaker server with a syntax that just feels right.}
  s.email = %q{http://groups.google.com/group/rfmcommunity}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    "lib/rfm.rb",
     "lib/rfm_command.rb",
     "lib/rfm_error.rb",
     "lib/rfm_factory.rb",
     "lib/rfm_result.rb",
     "lib/rfm_util.rb"
  ]
  s.homepage = %q{http://sixfriedrice.com/wp/products/rfm/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{FileMaker to Ruby adapter}
  s.test_files = [
    "test/rfm_test_errors.rb",
     "test/rfm_tester.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<hpricot>, [">= 0.8.1"])
    else
      s.add_dependency(%q<hpricot>, [">= 0.8.1"])
    end
  else
    s.add_dependency(%q<hpricot>, [">= 0.8.1"])
  end
end
