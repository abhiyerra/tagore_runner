# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = "tagore_runner"
  s.version = "0.1.#{ENV['BUILD_NUMBER'] || 'dev'}"
  s.platform = Gem::Platform::RUBY
  s.authors = ["Abhi Yerra"]
  s.email = ["abhi.yerra@mylookout.com"]
  s.homepage = ""
  s.summary = %q{gem that provides the runners for tagore}
  s.description = %q{}

  s.add_dependency('redis')
  s.add_dependency('json')
  s.add_dependency('rake')
  s.add_dependency('httparty')

  s.add_development_dependency('rspec')
  s.add_development_dependency('ruby-debug19')

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
