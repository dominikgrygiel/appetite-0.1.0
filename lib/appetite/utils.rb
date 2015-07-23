module AppetiteUtils

  include ::AppetiteConstants

  # "fluffing" potentially hostile paths.
  # to avoid paths traversing, replacing the matches below with a slash:
  # ../
  # /../
  # /..
  # ..\
  # \..\
  # \..
  # ..%2F
  # %2F..%2F
  # %2F..
  # ..%5C
  # %5C..%5C
  # %5C..
  #
  # @note
  #   it will also remove duplicating slashes.
  #
  # @note slow method! use only at load time
  #
  # @param [String, Symbol] *chunks
  # @return [String]
  #
  def normalize_path path
    path.gsub ::Regexp.union(/\\+/, /\/+/, *PATH_MODIFIERS), '/'
  end
  module_function :normalize_path

  # @note slow method! use only at load time
  def rootify_url *paths
    '/' << normalize_path(paths.map { |p| p.to_s }.join('/')).gsub(/\A\/+|\/+\Z/, '')
  end
  module_function :rootify_url

  # takes an arbitrary number of arguments and builds an HTTP path.
  # Hash arguments will transformed into HTTP params.
  # empty hash elements will be ignored.
  # @example
  #    ::AppetiteUtils.build_path :some, :page, and: :some_param
  #    #=> some/page?and=some_param
  #    ::AppetiteUtils.build_path 'another', 'page', with: {'nested' => 'params'}
  #    #=> another/page?with[nested]=params
  #    ::AppetiteUtils.build_path 'page', with: 'param-added', an_ignored_param: nil
  #    #=> page?with=param-added
  #
  # @param path
  # @param [Array] args
  # @return [String]
  #
  def build_path path, *args
    path = path.to_s
    args.compact!
    
    query_string = args.last.is_a?(Hash)  && (h = args.pop.delete_if{|k,v| v.nil?}).size > 0 ?
      '?' << ::Rack::Utils.build_nested_query(h) : ''
    
    args.size == 0 || path =~ /\/\Z/ || args.unshift('')
    path + args.join('/') << query_string
  end
  module_function :build_path

  def is_app? obj
    obj.respond_to? :base_url
  end
  module_function :is_app?

  # Enable string or symbol key access to the nested params hash.
  def indifferent_params(object)
    case object
    when Hash
      new_hash = indifferent_hash
      object.each { |key, value| new_hash[key] = indifferent_params(value) }
      new_hash
    when Array
      object.map { |item| indifferent_params(item) }
    else
      object
    end
  end
  module_function :indifferent_params

  # Creates a Hash with indifferent access.
  def indifferent_hash
    Hash.new {|hash,key| hash[key.to_s] if Symbol === key }
  end
  module_function :indifferent_hash
end
