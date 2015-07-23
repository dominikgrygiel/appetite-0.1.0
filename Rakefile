require 'rubygems'
require 'rake'

task :default => :test

require './test/setup'

task :test do

  ::Dir['./test/test__*.rb'].each { |f| require f }
  session = Specular.new
  session.boot { include Sonar }
  session.before do |app|
    if app && ::AppetiteUtils.is_app?(app)
      app.use Rack::Lint
      app(app.to_app!)
      map app.base_url
    end
  end
  session.run /AppetiteTest/, :trace => true
  puts session.skipped_specs
  puts session.skipped_tests
  puts session.failures if session.failed?
  puts session.summary
  session.exit_code == 0 || fail

end

task :overhead do
  require './test/overhead/run'
end
