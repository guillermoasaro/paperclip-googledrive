# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "paperclip/version"

Gem::Specification.new do |spec|
  spec.name          = "paperclip-googledrive"
  spec.version       = PaperclipGoogleDrive::VERSION
  spec.authors       = ['Diego Gomez']
  spec.email         = ["diego.f.gomez.pardo@gmail.com"]

  spec.summary       = %q{Extends Paperclip with Google Drive storage}
  spec.description   = %q{paperclip-googledrive extends paperclip support of storage for google drive storage}
  spec.homepage      = "https://github.com/degzcs/paperclip-googledrive"

  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.0.0"
  spec.license       = "MIT"

  spec.add_dependency "paperclip", ">= 5.1.0"
  spec.add_dependency 'google-api-client', "~> 0.9.20"

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 3"
  spec.add_development_dependency "webmock", "~> 2.1"
  spec.add_development_dependency "jazz_fingers", "~> 4"
  spec.add_development_dependency('activerecord', '>= 4.2.0')
  spec.add_development_dependency('sqlite3')
  spec.add_development_dependency('railties')
end
