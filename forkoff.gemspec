## forkoff.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "forkoff"
  spec.version = "1.2.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "forkoff"
  spec.description = "description: forkoff kicks the ass"
  spec.license = "Ruby"

  spec.files =
["README",
 "Rakefile",
 "forkoff.gemspec",
 "lib",
 "lib/forkoff.rb",
 "readme.erb",
 "samples",
 "samples/a.rb",
 "samples/b.rb",
 "samples/c.rb",
 "samples/d.rb",
 "test",
 "test/forkoff_test.rb"]

  spec.executables = []
  
  spec.require_path = "lib"

  spec.test_files = nil

  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/forkoff"
end
