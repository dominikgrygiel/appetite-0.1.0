
## Route

**[ [contents &uarr;](https://github.com/slivu/appetite#tutorial) ]**

Use `route` at class or instance level to get the URL of given action.

Returned URL will consist of app's base URL and the action's path.

If app does not respond to given action, it will simply use it as part of URL.

If called without arguments it will return app's base URL.

**Example:**

```ruby
class App < Appetite
    map '/books'

    def read
        # ...
    end

    def test
        route :read
        #=> /books/read
    end
end

Index.route
#=> /

Index.route :read
#=> /books/read

Index.route :blah
#=> /books/blah
```

If any params given(beside action name) they will become a part of generated URL.

**Example:**

```ruby
class News < Appetite

    def index
        route :latest___items, 100
        #=> /news/latest-items/100
    end

    def latest___items ipp = 10, order = 'asc'
    end
end

News.route
#=> /news

News.route :latest___items
#=> /news/latest-items

News.route :latest___items, 20, :desc
#=> /news/latest-items/20/desc
```

If a Hash given, it will be passed as query string.

**Example:**

```ruby
route :read, :var => 'val'
#=> /read?var=val

# nested params
route :view, :var => ['1', '2', '3']
#=> /view?var[]=1&var[]=2&var[]=3

route :open, :vars => {:var1 => '1', :var2 => '2'}
#=> /open?vars[var1]=1&vars[var2]=2
```

To get action route along with format, pass the action name as string, having desired format as suffix.<br/>
If action does not support given format, it will simply be used as a part of URL.

**Example:**

```ruby
class Rss < Appetite
    map :reader
    format :html, :xml

    def mini___news
        # ...
    end
end

Rss.route :mini___news
#=> /reader/mini-news

Rss.route 'mini___news.html'
#=> /reader/mini-news.html

Rss.route 'mini___news.xml'
#=> /reader/mini-news.xml

Rss.route 'mini___news.json'
#=> /reader/mini___news.json
```

You can also append format to last param and all the setups set at class level will be respected,
just as if format passed along with action name.

**Please note** that even when last param given with format,
inside action it will be passed without format,
so you do not need to remove format manually.

**Example:**

```ruby
class App < Appetite
    map '/'
    format :html

    def read item = nil
        # on /read                item == nil
        # on /read/news           item == "news"
        # on /read/book.html      item == "book"
        # on /read/100.html       item == "100"
        # on /read/etc.html       item == "etc"
        # on /read/blah.xml       item == "blah.xml"
    end
end

App.route :read, 'book.html'
#=> /read/book.html

App.route :read, '100.html'
#=> /read/100.html

App.route :read, 'etc.html'
#=> /read/etc.html

App.route :read, 'blah.xml'
#=> /read/blah.xml
```

If you need **just the action route, without any params**, use `[]` at class or instance level.

`[]` will return `nil` if given action not found or does not support the given format.

**Example:**

```ruby
class Index < Appetite
    map :cms
    format :html

    def read
    end

    def quick___reader
    end

    def test
        self[:read]
        #=> /cms/read

        self[:quick___reader]
        #=> /cms/quick-reader

        self['quick___reader.html']
        #=> /cms/quick-reader.html

        self['quick___reader.json']
        #=> nil

        self[:blah]
        #=> nil
    end
end

Index[:read]
#=> /cms/read

Index[:quick___reader]
#=> /cms/quick-reader

Index['quick___reader.html']
#=> /cms/quick-reader.html

Index['quick___reader.json']
#=> nil

Index[:blah]
#=> nil
```


## Halt

**[ [contents &uarr;](https://github.com/slivu/appetite#tutorial) ]**

`halt` will interrupt any process and send resopnse to browser.

Response is composed from params given.

`halt` accepts from 0 to 3 arguments.<br/>
If argument is a hash, it is added to headers.<br/>
If argument is a Integer, it is treated as Status-Code.<br/>
Any other arguments are treated as body.

If a single argument given and it is an Array, it is treated as a bare Rack response and instantly sent to browser.

**Example:**

```ruby
def index
    halt 'Hit the Road Jack' if SomeHelper.malicious_params?(env)
    # ...
end
```

**Example:** - Status code

```ruby
def index
    begin
        some risky code
    rescue => e
        halt 500, exception_to_human_error(e)
    end
end
```

**Example:** - Custom headers

```ruby
def news
    if params['return-rss']
        halt rssify(@items), 'Content-Type' => mime_type('.rss')
    end
end
```

**Example:** - Rack response

```ruby
def download
    halt [200, {'Content-Disposition' => "attachment; filename=some-file"}, some_IO_instance]
end
```

## Redirect

**[ [contents &uarr;](https://github.com/slivu/appetite#tutorial) ]**

`redirect` will interrupt any process and redirect browser to new address with status code 302.

To redirect with status code 301 use `permanent_redirect`.

To wait untill request processed use `delayed_redirect` or `deferred_redirect`.

If an exisitng action passed as first argument, it will use the route of given action for location.

If first argument is a valid Appetite app, it will use given app's setup to build path.

**Example:** - Basic redirect with hardcoded location(bad practice way in most cases)

```ruby
redirect '/some/path'
```

**Example:** - Basic redirect with dynamic location

```ruby
class Articles < Appetite

    def index
        redirect route # => /articles
        redirect :read, 100 # => /articles/read/100
        redirect News # => /news
        redirect News, :read, 100 # => /news/read/100
    end

    def read id
    end
end
```


## Reload

**[ [contents &uarr;](https://github.com/slivu/appetite#tutorial) ]**

`reload`  will simply refresh the page.

**Example:** - Refreshing with same GET params

```ruby
def index
    # ...
    reload
end
```

**Example:** - Refreshing with custom GET params

```ruby
def index
    # ...
    reload :some => 'param', :some_another => 'param'
end
```


## Headers

**[ [contents &uarr;](https://github.com/slivu/appetite#tutorial) ]**

`response.headers` or just `response[]` allow to read/set headers to be sent to browser.

**Example:**

```ruby
response['Max-Forwards']
#=> nil

response['Max-Forwards'] = 5

response['Max-Forwards']
#=> 5

# browser will receive Max-Forwards=5 header
```
