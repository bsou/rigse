# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ffi-ncurses}
  s.version = "0.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sean O'Halpin"]
  s.date = %q{2009-02-22}
  s.description = %q{A wrapper for ncurses 5.x. Tested on Mac OS X 10.4 (Tiger) and Ubuntu 8.04 with ruby 1.8.6 using ruby-ffi (>= 0.2.0) and JRuby 1.1.6.  The API is very much a transliteration of the C API rather than an attempt to provide an idiomatic Ruby object-oriented API. The intent is to provide a 'close to the metal' wrapper around the ncurses library upon which you can build your own abstractions.  See the examples directory for real working examples.}
  s.email = %q{sean.ohalpin@gmail.com}
  s.extra_rdoc_files = ["History.txt", "README.rdoc"]
  s.files = ["History.txt", "README.rdoc", "Rakefile", "examples/doc-eg1.rb", "examples/doc-eg2.rb", "examples/doc-eg3.rb", "examples/example-attributes.rb", "examples/example-colour.rb", "examples/example-cursor.rb", "examples/example-getsetsyx.rb", "examples/example-hello.rb", "examples/example-jruby.rb", "examples/example-keys.rb", "examples/example-mouse.rb", "examples/example-printw-variadic.rb", "examples/example-softkeys.rb", "examples/example-stdscr.rb", "examples/example-windows.rb", "examples/example.rb", "examples/ncurses-example.rb", "ffi-ncurses.gemspec", "lib/ffi-ncurses.rb", "lib/ffi-ncurses/darwin.rb", "lib/ffi-ncurses/keydefs.rb", "lib/ffi-ncurses/mouse.rb", "lib/ffi-ncurses/winstruct.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/seanohalpin/ffi-ncurses}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{ffi-ncurses}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{FFI wrapper for ncurses}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bones>, [">= 2.4.0"])
    else
      s.add_dependency(%q<bones>, [">= 2.4.0"])
    end
  else
    s.add_dependency(%q<bones>, [">= 2.4.0"])
  end
end
