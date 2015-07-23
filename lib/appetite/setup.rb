class << Appetite

  include AppetiteUtils

  # setting app's root path.
  #
  # if multiple paths provided, first path is treated as root,
  # and other ones are treated as canonical routes.
  # canonical routes allow app to serve multiple roots.
  #
  # @note can be set only by app
  def map *paths
    return if locked?
    @base_url = rootify_url(paths.shift.to_s).freeze
    @canonicals = paths.map { |p| rootify_url(p.to_s) }.freeze
  end

  # set some config only for given actions
  #
  # @example
  #    setup :read, :book do
  #      format :html
  #    end
  #
  def setup *actions, &proc
    (@setup_procs ||= []) << [proc, actions.size > 0 ? actions : [:*]]
  end

  # add/update a path rule
  #
  # @note default rules
  #    - "__"   (2 underscores) => "-" (dash)
  #    - "___"  (3 underscores) => "/" (slash)
  #    - "____" (4 underscores) => "." (period)
  #
  # @example define custom rules
  #    path_rule  "__dh__" => "-",
  #    path_rule  "__dt__" => "."
  #
  #    def some__dh__action__dt__html
  #      # will resolve to some-action.html
  #    end
  #
  # @note it does not make sense to lock this
  #       cause path rules are used only at load time
  def path_rule from, to
    path_rules[from] || path_rule!(from, to)
  end

  def path_rule! from, to
    path_rules.update from => to
  end

  # @note it does not make sense to lock this
  #       cause path rules are used only load time
  # return [Hash]
  def path_rules
    @path_rules ||= {
      '____' => '.',
      '___' => '-',
      '__' => '/',
    }
  end

  # allow to set routes directly, without relying on path rules.
  #
  # @example make :bar method to serve /bar, /some/url and /some/another/url
  #   def bar
  #     # ...
  #   end
  # 
  #   action_alias 'some/url', :bar
  #   action_alias 'some/another/url', :bar
  #
  # @example make :foo method to serve only /some/url
  #
  #   action_alias 'some/url', :foo
  # 
  #   private
  #   def foo
  #     # ...
  #   end
  def action_alias url, action
    ((@action_aliases||={})[action]||=[]) << url
  end


  # automatically setting Content-Type depending on URL extension
  #
  # @example :pages and :news actions will respond to URLs ending in .html and .xml
  #
  #  class App < Appetite
  #
  #      setup :pages, :news do
  #          format :xml, :html
  #      end
  #
  #      # ...
  #  end
  #  # voila, now the app will respond to any of
  #  # /pages, /pages.html, /pages.xml, /news, /news.html, /news.xml,
  #  # and returning proper content type depending on extension.
  def format *formats
    format! *formats << true
  end

  def format! *formats
    return if locked? || formats.empty?
    format?
    keep_existing = formats.delete(true)
    setup__actions.each do |a|
      next if @format[a] && keep_existing
      @format[a] = (normalized_formats ||= formats.map { |f| '.' << f.to_s.sub(/\A\.+/, '') })
    end
  end

  def format? action = nil
    @format ||= {}
    @format[action] || @format[:*] || []
  end

  # declaring rewrite rules.
  #
  # first argument should be a regex and a proc should be provided.
  #
  # the regex(actual rule) will be compared against Request URI,
  # i.e. current URL without query string.
  # if some rule depend on query string,
  # use `params` inside proc to determine either some param was or not set.
  #
  # the proc will decide how to operate when rule matched.
  # you can do:
  # `redirect('location')`
  #     redirect to new location using 302 status code
  # `permanent_redirect('location')`
  #     redirect to new location using 301 status code
  # `pass(app, action, any, params, with => opts)`
  #     pass control to given app and action without redirect.
  #     consequent params are used to build URL to be sent to given app.
  # `halt(status|body|headers|response)`
  #     send response to browser without redirect.
  #     accepts an arbitrary number of arguments.
  #     if arg is an Integer, it will be used as status code.
  #     if arg is a Hash, it is treated as headers.
  #     if it is an array, it is treated as Rack response and are sent immediately, ignoring other args.
  #     any other args are treated as body.
  #
  # @note any method available to app instance are also available inside rule proc.
  #       so you can fine tune the behavior of any rule.
  #       ex. redirect on GET requests and pass control on POST requests.
  #       or do permanent redirect for robots and simple redirect for browsers etc.
  #
  # @example
  #    class App < Appetite
  #
  #      # redirect to new address, inside current app
  #      rewrite /\A\/(.*)\.php$/ do |title|
  #        redirect route(:index, title)
  #      end
  #
  #      # redirect to an URL on inner app
  #      rewrite /\A\/(.*)\.php$/ do |title|
  #        redirect SomeApp.route(:some_action, title)
  #      end
  #
  #      # permanent redirect, i.e. with 301 code
  #      rewrite /\A\/news\/([\w|\d]+)\-(\d+)\.html/ do |title, id|
  #        permanent_redirect route(:posts, :title => title, :id => id)
  #      end
  #
  #      # no redirect, just pass control to :read action of current app
  #      rewrite /\A\/(.*)\.html\Z/ do |title|
  #        pass :read, :title => title
  #      end
  #
  #      # no redirect, just pass control to :index action of News app
  #      rewrite /\A\/latest\/(.*)\.html/ do |title|
  #        pass News, :index, :scope => :latest, :title => title
  #      end
  #
  #      # Return arbitrary body/status-code/headers, without redirect:
  #      # If argument is a Hash, it is added to headers.
  #      # If argument is a Integer, it is treated as Status-Code.
  #      # Any other arguments are treated as body.
  #      rewrite /\A\/archived\/(.*)\.html\Z/ do |title|
  #        page = Model::Page.first(:url => title) || halt(404, 'page not found')
  #        halt page.content, 'Last-Modified' => page.last_modified.to_rfc2822
  #      end
  #
  #      # ...
  #
  #    end
  #
  def rewrite rule, &proc
    rewrite_rules << [rule, proc] if proc
  end

  alias rewrite_rule rewrite

  def rewrite_rules
    @rewrite_rules ||= []
  end

  # add Rack middleware to chain
  def use ware, *args, &proc
    return if locked?
    use? << {:ware => ware, :args => args, :proc => proc}
  end

  def use?
    @middleware ||= []
  end

end
