# -*- encoding: utf-8 -*-

version = "0.1.0"
Gem::Specification.new do |s|

  s.name = 'appetite'
  s.version = version
  s.authors = ['Silviu Rusu']
  s.email = ['slivuz@gmail.com']
  s.homepage = 'https://github.com/slivu/appetite'
  s.summary = 'Appetite-%s' % version
  s.description = "Low-Latency Rack Mapper. Turn any class into a Petite Rack App"

  s.required_ruby_version = '>= 1.8.7'

  s.add_dependency 'rack', '~> 1.4'

  s.add_development_dependency 'rake', '~> 10'
  s.add_development_dependency 'specular', '>= 0.1.6'
  s.add_development_dependency 'sonar', '>= 0.1.2'

  s.require_paths = ['lib']
  s.files = Dir['**/*'].reject {|e| e =~ /\.(gem|lock)\Z/}
end
