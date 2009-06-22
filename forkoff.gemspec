## forkoff.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "forkoff"
  spec.version = "0.0.4"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "forkoff"

  spec.files = ["lib", "lib/forkoff.rb", "rakefile", "README", "readme.erb", "samples", "samples/a.rb", "samples/b.rb", "samples/c.rb", "samples/d.rb"]
  spec.executables = []
  
  spec.require_path = "lib"

  spec.has_rdoc = true
  spec.test_files = nil
  #spec.add_dependency 'lib', '>= version'
  #spec.add_dependency 'fattr'

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "http://github.com/ahoward/forkoff/tree/master"
end
