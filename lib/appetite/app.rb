class << Appetite

  # returns URL set by `map` or the underscored app name
  # @return [String]
  def base_url
    @base_url ||= ('/' << self.name.to_s.split('::').last.
        gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase).freeze
  end
  alias baseurl base_url

  # build URL from given action name(or path) and consequent params
  # @return [String]
  def route *args
    locked? || raise("`route' works only on mounted apps. Please consider to use `base_url' instead.")
    return base_url if args.size == 0
    (route = self[args.first]) && args.shift
    build_path(route || base_url, *args)
  end

  # @example
  #    class Forum < Appetite
  #      format :html, :xml
  #
  #      def posts
  #      end
  #    end
  #
  #    App[:posts]
  #    #=> /forum/posts
  #    App['posts.html']
  #    #=> /forum/posts.html
  #    App['posts.xml']
  #    #=> /forum/posts.xml
  #    App['posts.json']
  #    #=> nil
  def [] action_or_action_with_format
    locked? || raise("`[]' method works only on mounted apps.")
    @action_map[action_or_action_with_format]
  end

  # rack middleware interface.
  # allow to quick run app without any setup,
  # just like `run App`
  def call env
    app.call env
  end

  def app
    @app ||= mount!
  end

  alias to_app app
  alias to_app! app

  # building rack app.
  # it also allow to setup or override setup of the app.
  # if any roots given, app will serve given roots instead of ones defined at class level.
  # also, if you need to setup the app, use a block with desired setup methods.
  # if you need to override some setups, use bang methods inside block.
  # setup overriding are useful when you can not modify the app at class level,
  # for ex. when some app are distributed as a gem.
  #
  # @example we have a Forum app, actually a gem, that serve /Forums base URL.
  #          but we need it to serve /forum without modify/override its source.
  #
  #    require 'my-forum-gem'
  #
  #    run Forum.mount '/forum'
  #
  # @example same forum, its URLs ending in .php, we need .html instead
  #
  #    require 'my-forum-gem'
  #
  #    app = Forum.mount '/forum' do
  #      format! '.html'
  #    end
  #    run app
  #
  # @note ANY CONTROLLER CAN BE MOUNTED ONLY ONCE!
  #       if you need some controller to run on multiple roots
  #       pass the roots as arguments at mount.
  #
  # @example same forum, we need it to serve multiple base URLs
  #
  #    require 'my-forum-gem'
  #
  #    run Forum.mount '/forum', '/forums', '/bulletin'
  #
  def mount *roots, &setup
    return @app if @app

    self.map(*roots) if roots.size > 0
    self.class_exec(&setup) if setup

    setup!
    map!

    builder, app = ::Rack::Builder.new, self
    use?.each { |w| builder.use w[:ware], *w[:args], &w[:proc] }
    url_map.each_key do |route|
      builder.map route do
        run lambda { |env| app.new.call env }
      end
    end
    
    freeze!
    lock!

    @app = rewrite_rules.size > 0 ?
      ::AppetiteRewriter.new(rewrite_rules, builder.to_app, self) :
      builder.to_app
  end
  alias mount! mount

  # call this only after all actions defined
  def setup!
    return unless @setup_procs
    http_actions = actions
    @setup_procs.each do |setup_proc|
      proc, actions = setup_proc
      @setup__actions = actions.map do |action|

        action.is_a?(Regexp) ?
          http_actions.select { |a| a.to_s =~ action } :
          action.is_a?(String) && action =~ /\A\./ ?
            http_actions.map { |a| a.to_s << action if format?(a).include?(action) }.compact :
            action

      end.flatten
      self.class_exec &proc
      @setup__actions = nil
    end
    @setup_procs = nil
  end

  # @api semi-public
  #
  # build action_map and url_map.
  #
  # action_map is a hash having actions as keys
  # and showing what urls are served by each action.
  #
  # url_map is a hash having urls as keys
  # and showing to what action by what request method each url is mapped.
  def map!
    return if locked?
    @action_map, @url_map = {}, {}

    actions.each do |action|
      request_methods, routes = action_routes(action)
      @action_map[action] = routes.first[nil].first
      routes.each do |route_map|
        route_map.each_pair do |format, route_setup|
          route, canonical = route_setup
          request_methods.each do |request_method|
            (@url_map[route] ||= {})[request_method] =
              [format, canonical, action, *action_parameters(action)]
          end
          next unless format
          @action_map[action.to_s + format] = route
        end
      end
    end
  end

  def canonicals
    @canonicals || []
  end
  alias canonical canonicals

  def url_map
    @url_map
  end
  alias urlmap url_map

  def locked?
    @locked
  end

  # @api semi-public
  def freeze!
    @action_map.freeze
    @url_map.freeze
  end

  # prohibit setup alteration at run time
  def lock!
    freeze!
    @locked = true
    self
  end

  private

  # methods to be translated to HTTP paths.
  # if app has no methods, defining #index with some placeholder text.
  #
  # @example
  #    class News < Appetite
  #      map '/news'
  #
  #      def index
  #        # ...
  #      end
  #      # will serve GET /news/index and GET /news
  #
  #      def post_index
  #        # ...
  #      end
  #      # will serve POST /news/index and POST /news
  #    end
  #
  # @example
  #    class Forum < Appetite
  #      map '/forum'
  #
  #      def online_users
  #        # ...
  #      end
  #      # will serve GET /forum/online_users
  #
  #      def post_create_user
  #        # ...
  #      end
  #      # will serve POST /forum/create_user
  #    end
  #
  # HTTP path params passed to action as arguments.
  # if arguments does not meet requirements, HTTP 404 error returned.
  #
  # @example
  #    def foo arg1, arg2
  #    end
  #    # /foo/some-arg/some-another-arg        - OK
  #    # /foo/some-arg                         - 404 error
  #
  #    def foo arg, *args
  #    end
  #    # /foo/at-least-one-arg                 - OK
  #    # /foo/one/or/any/number/of/args        - OK
  #    # /foo                                  - 404 error
  #
  #    def foo arg1, arg2 = nil
  #    end
  #    # /foo/some-arg/                        - OK
  #    # /foo/some-arg/some-another-arg        - OK
  #    # /foo/some-arg/some/another-arg        - 404 error
  #    # /foo                                  - 404 error
  #
  #    def foo arg, *args, last
  #    end
  #    # /foo/at-least/two-args                - OK
  #    # /foo/two/or/more/args                 - OK
  #    # /foo/only-one-arg                     - 404 error
  #
  #    def foo *args
  #    end
  #    # /foo                                  - OK
  #    # /foo/any/number/of/args               - OK
  #
  #    def foo *args, arg
  #    end
  #    # /foo/at-least-one-arg                 - OK
  #    # /foo/one/or/more/args                 - OK
  #    # /foo                                  - 404 error
  #
  # @return [Array]
  def actions
    actions = ((self.instance_methods(false) - ::Object.methods) + (@action_aliases||{}).keys).
      reject { |a| a.to_s =~ /__appetite__/ }.
      map { |a| a.to_sym }
    return actions if actions.size > 0

    define_method :index do |*|
      'Get rid of this placeholder by defining %s#index' % self.class
    end

    [:index]
  end

  # returns the served request_method(s) and routes served by given action.
  #
  # each action can serve one or more routes.
  # if no verb given, the action will respond to any request method.
  # to define an action serving only POST request method, prepend post_ or POST_ to action name.
  # same for any other request method.
  #
  # @example
  #    def read
  #      # will respond to any request method
  #    end
  #
  #    def post_login
  #      # will respond only to POST request method
  #    end
  #
  # @return [Array]
  def action_routes action
    request_methods, route = REQUEST_METHODS, action.to_s
    REQUEST_METHODS.each do |m|
      regex = /\A#{m}_/i
      if route =~ regex
        request_methods = [m]
        route = route.sub regex, ''
        break
      end
    end

    route.size == 0 && raise('wrong action name "%s"' % action)

    path_rules.keys.sort.reverse.each do |key|
      route = route.gsub(key.is_a?(Regexp) ? key : /#{key}/, path_rules[key])
    end

    pages, dirs = [], []
    path = rootify_url(base_url, route)
    pages << {nil => [path, nil]}
    dirs  << {nil => [rootify_url(base_url), path]} if route == APPETITE__INDEX_ACTION

    ((@action_aliases||{})[action]||[]).each do |url|
      pages << {nil => [rootify_url(base_url, url), nil]}
    end

    canonicals.each do |c|
      canonical_path = rootify_url(c, route)
      pages << {nil => [canonical_path, path]}
      dirs  << {nil => [rootify_url(c), path]} if route == APPETITE__INDEX_ACTION
    end
    pages.each do |page|
      format?(action).each { |format| page[format] = page[nil].first + format }
    end
    [request_methods, pages + dirs].freeze
  end

  if RESPOND_TO__PARAMETERS
    # returning required parameters calculated by arity,
    # and, if available, parameters list.
    def action_parameters action
      method = self.instance_method(action)

      parameters = method.parameters
      min, max = 0, parameters.size

      unlimited = false
      parameters.each_with_index do |param, i|

        increment = param.first == :req

        if (next_param = parameters.values_at(i+1).first)
          increment = true if next_param[0] == :req
        end

        if param.first == :rest
          increment = false
          unlimited = true
        end
        min += 1 if increment
      end
      max = nil if unlimited
      [parameters, [min, max]]
    end
  else
    def action_parameters action
      method = self.instance_method(action)
      min = max = (method.arity < 0 ? -method.arity - 1 : method.arity)
      [nil, [min, max]]
    end
  end

  def setup__actions
    @setup__actions || [:*]
  end

end
