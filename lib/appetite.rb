require 'time'

require 'rubygems'
require 'rack'

class Appetite
end

module AppetiteConstants

  RESPOND_TO__PARAMETERS = method(methods.first).respond_to?(:parameters)
  RESPOND_TO__SOURCE_LOCATION = proc {}.respond_to?(:source_location)

  REQUEST_METHODS = %w[GET POST PUT HEAD DELETE OPTIONS PATCH].freeze

  STATUS__OK = 200
  STATUS__REDIRECT = 302
  STATUS__PERMANENT_REDIRECT = 301
  STATUS__NOT_FOUND = 404
  STATUS__SERVER_ERROR = 500

  ENV__SCRIPT_NAME    = 'SCRIPT_NAME'.freeze
  ENV__REQUEST_METHOD = 'REQUEST_METHOD'.freeze
  ENV__PATH_INFO      = 'PATH_INFO'.freeze
  ENV__HTTP_ACCEPT    = 'HTTP_ACCEPT'.freeze
  ENV__QUERY_STRING   = 'QUERY_STRING'.freeze
  ENV__REMOTE_USER    = 'REMOTE_USER'.freeze
  ENV__HTTP_X_FORWARDED_HOST    = 'HTTP_X_FORWARDED_HOST'.freeze
  ENV__HTTP_IF_NONE_MATCH       = 'HTTP_IF_NONE_MATCH'.freeze
  ENV__HTTP_IF_MODIFIED_SINCE   = 'HTTP_IF_MODIFIED_SINCE'.freeze
  ENV__HTTP_IF_UNMODIFIED_SINCE = 'HTTP_IF_UNMODIFIED_SINCE'.freeze

  HEADER__CONTENT_TYPE  = 'Content-Type'.freeze
  HEADER__LAST_MODIFIED = 'Last-Modified'.freeze
  HEADER__CACHE_CONTROL = 'Cache-Control'.freeze
  HEADER__EXPIRES       = 'Expires'.freeze
  HEADER__CONTENT_DISPOSITION = 'Content-Disposition'.freeze

  PATH_MODIFIERS = [
      /\A\.\.\Z/,
      '../', '/../', '/..',
      '..%2F', '%2F..%2F', '%2F..',
      '..\\', '\\..\\', '\\..',
      '..%5C', '%5C..%5C', '%5C..',
  ].freeze

  APPETITE__INDEX_ACTION = 'index'.freeze

end

require 'appetite/utils'
require 'appetite/setup'
require 'appetite/rewriter'
require 'appetite/request'
require 'appetite/base'
require 'appetite/app'
