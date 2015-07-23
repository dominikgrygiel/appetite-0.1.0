class AppetiteRewriter

  include ::AppetiteUtils
  include ::Rack::Utils

  attr_reader :env, :request

  def initialize rewrite_rules, app, app_setup = nil
    @rewrite_rules, @app, @app_setup = rewrite_rules, app, app_setup
  end

  def call env
    @env, @request = env, ::Rack::Request.new(env)
    matched? ? [@status, @headers, @body] : @app.call(env)
  end

  def matched?
    path = request.path
    @status, @headers, @body = nil, {}, []

    catch :__appetite__rewriter__halt_symbol__ do
      @rewrite_rules.each do |rule|
        next unless (matches = path.match(rule.first))
        self.instance_exec *matches.captures, &rule.last
        break
      end
    end
    @status
  end

  def route *args
    @app_setup || raise(ArgumentError, 'App missing. Please provide is as first param when calling `route` inside a rewrite rule block.')
    @app_setup.route *args
  end

  def redirect location
    @status = STATUS__REDIRECT
    @headers['Location'] = location
  end

  def permanent_redirect location
    redirect location
    @status = STATUS__PERMANENT_REDIRECT
  end

  def pass *args
    app = (args.size > 0 && is_app?(args.first) && args.shift) || @app_setup ||
      raise(ArgumentError, "App missing. Please provide it as first argument when calling `pass' inside a rewrite rule block.")

    action = args.shift
    route = app[action] ||
        raise(ArgumentError, '%s app does not respond to %s action' % [app, action.inspect])
    rest_map = app.url_map[route]

    env.update 'SCRIPT_NAME' => route, 'REQUEST_URI' => '', 'PATH_INFO' => ''
    if args.size > 0
      path, params = '/', {}
      args.each { |a| a.is_a?(Hash) ? params.update(a) : path << a.to_s << '/' }
      env.update('PATH_INFO' => path)
      params.size > 0 &&
          env.update('QUERY_STRING' => build_nested_query(params))
    end
    @status, @headers, @body = app.new.call(env)
  end

  def halt *args
    args.each do |a|
      case
        when a.is_a?(Array)
          @status, @headers, @body = a
        when a.is_a?(Fixnum)
          @status = a
        when a.is_a?(Hash)
          @headers.update a
        else
          @body = [a]
      end
    end
    @status ||= STATUS__OK
    throw :__appetite__rewriter__halt_symbol__
  end

end
