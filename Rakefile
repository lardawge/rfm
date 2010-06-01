require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "lardawge-rfm"
    gem.summary = "Ruby to Filemaker adapter"
    gem.description = "Rfm brings your FileMaker data to Ruby. Now your Ruby scripts and Rails applications can talk directly to your FileMaker server."
    gem.email = "http://groups.google.com/group/rfmcommunity"
    gem.homepage = "http://sixfriedrice.com/wp/products/rfm/"
    gem.authors = ["Geoff Coffey", "Mufaddal Khumri", "Atsushi Matsuo", "Larry Sprock"]
    gem.files = FileList['lib/**/*']
    gem.add_dependency('nokogiri')
    gem.rdoc_options = [ "--line-numbers", "--main", "README.rdoc" ]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rfm #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

