class Appetite

  include ::Rack::Utils
  include ::AppetiteConstants

  def call env, &proc
    @__appetite__env = env
    rack_response = catch :__appetite__catch__response__ do

      script_name = env[ENV__SCRIPT_NAME]
      script_name = '/' if script_name.size == 0
      rest_map    = self.class.url_map[script_name] || {}
      
      @__appetite__format,
        @__appetite__canonical,
        @__appetite__action,
        @__appetite__action_arguments, required_arguments =
        (rest_map[env[ENV__REQUEST_METHOD]] || []).map { |e| e.freeze }

      @__appetite__request = AppetiteRequest.new(env)
      action || error(STATUS__NOT_FOUND)

      min, max = required_arguments
      given    = action_params__array.size

      min && given < min &&
        error(STATUS__NOT_FOUND, 'min params accepted: %s; params given: %s' % [min, given])

      max && given > max &&
        error(STATUS__NOT_FOUND, 'max params accepted: %s; params given: %s' % [max, given])

      if format.nil? && given > 0 && (formats = self.class.format?(action)).any?

        # if action serve some formats and last param extension matches some of them,
        # removing matching extension so user get clean param.
        # ex: /foo/bar.html becomes ['foo', 'bar']
        last_param_ext = ::File.extname(action_params__array.last)

        if last_param_ext.size > 0 &&
          format = formats.select { |f| last_param_ext == f }.first
          params = Array.new(action_params__array) # faster than dup
          params[given - 1] = ::File.basename(params.last, format)
          @__appetite__action_params__array = params.freeze
          @__appetite__format = format.freeze
        end
      end
      response[HEADER__CONTENT_TYPE] = mime_type(format()) if format()

      action__invoke &proc

      response
    end
    rack_response.body = [] if request.head?
    rack_response.finish
  end

  def env
    @__appetite__env
  end

  def request
    @__appetite__request
  end
  alias rq request

  def response
    @__appetite__response ||= Rack::Response.new
  end
  alias rs response

  def params
    @__appetite__params ||= AppetiteUtils.indifferent_params(request.params)
  end

  # Set or retrieve the response status code.
  def status(value=nil)
    response.status = value if value
    response.status
  end

  def base_url
    self.class.base_url
  end
  alias baseurl base_url

  def action__invoke &proc
    response.body = nil
    body = proc ? self.instance_exec(&proc) : self.send(action, *action_params__array)
    response.body ||= [body.to_s]
  end

  def action
    @__appetite__action
  end

  def action_with_format
    @__appetite__action_with_format ||= 
      (format ? action.to_s + format : action).freeze
  end

  def action_params__array
    @__appetite__action_params__array ||=
      env[ENV__PATH_INFO].to_s.split('/').select { |s| s.size > 0 }.freeze
  end

  if RESPOND_TO__PARAMETERS
    # @example ruby 1.9+
    #    def index id, status
    #      action_params
    #    end
    #    # /100/active
    #    #> {:id => '100', :status => 'active'}
    def action_params
      return @__appetite__action_params if @__appetite__action_params

      action_params, given_params = {}, action_params__array.dup
      @__appetite__action_arguments.each_with_index do |type_name, index|
        type, name = type_name
        if type == :rest
          action_params[name] = []
          until given_params.size < (@__appetite__action_arguments.size - index)
            action_params[name] << given_params.shift
          end
        else
          action_params[name] = given_params.shift
        end
      end
      @__appetite__action_params = AppetiteUtils.indifferent_params(action_params).freeze
    end
  else
    # @example ruby 1.8
    #    def index id, status
    #      action_params
    #    end
    #    # /100/active
    #    #> ['100', 'active']
    alias action_params action_params__array
  end

  def format
    @__appetite__format
  end
  alias format? format

  def canonical
    @__appetite__canonical
  end
  alias canonical? canonical

  def [] action
    self.class[action]
  end

  def route *args
    self.class.route *args
  end

  # stop executing any code and send response to browser.
  #
  # accepts an arbitrary number of arguments.
  # if arg is an Integer, it will be used as status code.
  # if arg is a Hash, it is treated as headers.
  # if it is an array, it is treated as Rack response and are sent immediately, ignoring other args.
  # any other args are treated as body.
  #
  # @example returning "Well Done" body with 200 status code
  #    halt 'Well Done'
  #
  # @example halting quietly, with empty body and 200 status code
  #    halt
  #
  # @example returning error with 500 code:
  #    halt 500, 'Sorry, some fatal error occurred'
  #
  # @example custom content type
  #    halt File.read('/path/to/theme.css'), 'Content-Type' => mime_type('.css')
  #
  # @example sending custom Rack response
  #    halt [200, {'Content-Disposition' => "attachment; filename=some-file"}, some_IO_instance]
  #
  # @param [Array] *args
  def halt *args
    args.each do |a|
      case
        when a.is_a?(Fixnum)
          response.status = a
        when a.is_a?(Array)
          status, headers, body = a
          response.status = status
          response.headers.update headers
          response.body = body
        when a.is_a?(Hash)
          response.headers.update a
        else
          response.body = [a.to_s]
      end
    end
    response.body ||= []
    throw :__appetite__catch__response__, response
  end

  def error status, body = nil
    body.nil? && (status == 404) && 
      (body = '<h2>404 Not Found: %s</h2>' % env[ENV__PATH_INFO])
    halt status.to_i, body
  end

  # simply reload the page, using current GET params.
  # to use custom GET params, pass a hash as first argument.
  #
  # @param [Hash, nil] params
  def reload params = nil
    redirect request.path, params || request.GET
  end

  # stop any action/hook and redirect right away.
  # path is built by passing given args to route
  def redirect *args
    delayed_redirect STATUS__REDIRECT, *args
    halt
  end

  def permanent_redirect *args
    delayed_redirect STATUS__PERMANENT_REDIRECT, *args
    halt
  end

  # ensure the browser will be redirected after action/hook finished.
  def delayed_redirect *args
    status = args.first.is_a?(Numeric) ? args.shift : STATUS__REDIRECT
    app = ::AppetiteUtils.is_app?(args.first) ? args.shift : nil
    action = args.first.is_a?(Symbol) ? args.shift : nil
    if app && action
      target = app.route action, *args
    elsif app
      target = app.route *args
    elsif action
      target = route action, *args
    else
      target = ::AppetiteUtils.build_path *args
    end
    response.body = []
    response.redirect target, status
  end
  alias deferred_redirect delayed_redirect

  # shortcut for Rack::Mime::MIME_TYPES.fetch
  def mime_type type, fallback = nil
    ::Rack::Mime::MIME_TYPES.fetch type, fallback
  end

end
