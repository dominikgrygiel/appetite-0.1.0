Appetite - Low-Latency Rack Mapper
---

<a href="https://travis-ci.org/slivu/appetite">
<img src="https://travis-ci.org/slivu/appetite.png" align="right"></a>

**Easily turn any Class into a Petite Rack App**

**Really useful at building High-Load APIs and Web Frameworks**

Quick Start
---

**Ready**

    $ [sudo] gem install appetite

**Set**

    $ nano config.ru

```ruby
require 'appetite'

class App < Appetite
    map '/'

    def index name
        'Hello! My name is %s' % name
    end
end

run App
```

**Go!**

    $ rackup
    >> Thin web server (v1.4.1 codename Chromeo)
    >> Maximum connections set to 1024
    >> Listening on 0.0.0.0:9292, CTRL+C to stop

<pre>
$ http GET :9292/Appetite
HTTP/1.1 200 OK
Content-Type: text/html
Transfer-Encoding: chunked
Connection: close
Server: thin 1.4.1 codename Chromeo

Hello! My name is Appetite

</pre>

## Tutorial


### Routing

[Base URL](https://github.com/slivu/appetite/blob/master/Routing.md#base-url) |
[Canonicals](https://github.com/slivu/appetite/blob/master/Routing.md#canonicals) |
[Actions](https://github.com/slivu/appetite/blob/master/Routing.md#actions) |
[Action Mapping](https://github.com/slivu/appetite/blob/master/Routing.md#action-mapping) |
[Action Aliases](https://github.com/slivu/appetite/blob/master/Routing.md#action-aliases) |
[Parametrization](https://github.com/slivu/appetite/blob/master/Routing.md#parametrization) |
[Format](https://github.com/slivu/appetite/blob/master/Routing.md#format) |
[RESTful Actions](https://github.com/slivu/appetite/blob/master/Routing.md#restful-actions) |
[Aliases](https://github.com/slivu/appetite/blob/master/Routing.md#aliases) |
[Rewriter](https://github.com/slivu/appetite/blob/master/Routing.md#rewriter)

### Workflow

[Route](https://github.com/slivu/appetite/blob/master/Workflow.md#route) |
[Halt](https://github.com/slivu/appetite/blob/master/Workflow.md#halt) |
[Redirect](https://github.com/slivu/appetite/blob/master/Workflow.md#redirect) |
[Reload](https://github.com/slivu/appetite/blob/master/Workflow.md#reload) |
[Headers](https://github.com/slivu/appetite/blob/master/Workflow.md#headers)

<hr/>
