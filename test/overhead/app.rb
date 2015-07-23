$:.unshift File.expand_path('../../../lib', __FILE__)
require 'appetite'

class App < Appetite
  map '/'

  def index
    "Hello World!"
  end
end
Rack::Handler::Thin.run App, Port: $*[0].to_i
