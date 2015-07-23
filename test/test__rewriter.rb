module AppetiteTest__Rewriter

  class Cms < Appetite
    map '/'

    rewrite /\A\/articles\/(\d+)\.html$/ do |title|
      redirect '/page?title=%s' % title
    end

    rewrite /\A\/landing\-page\/([\w|\d]+)\/([\w|\d]+)/ do |page, product|
      redirect Store.route(:buy, product, :page => page)
    end

    rewrite /\A\/News\/(.*)\.php/ do |name|
      redirect route(:news, name, (request.query_string.size > 0 ? '?' << request.query_string : ''))
    end

    rewrite /\A\/old_news\/(.*)\.php/ do |name|
      permanent_redirect route(:news, name)
    end

    rewrite /\A\/pages\/+([\w|\d]+)\-(\d+)\.html/i do |name, id|
      redirect route(:page, name, :id => id)
    end

    rewrite /\A\/old_pages\/+([\w|\d]+)\-(\d+)\.html/i do |name, id|
      permanent_redirect "/page?name=#{ name }&id=#{ id }"
    end

    rewrite /\A\/pass_test_I\/(.*)/ do |name|
      pass :test_pass, name, :name => name
    end

    rewrite /\A\/pass_test_II\/(.*)/ do |name|
      pass Store, :buy, name, :name => name
    end

    rewrite /\A\/halt_test_I\/(.*)\/(\d+)/ do |body, code|
      halt body, code.to_i, 'TEST' => '%s|%s' % [body, code]
      raise 'this shit should not be happen'
    end

    rewrite /\A\/halt_test_II\/(.*)\/(\d+)/ do |body, code|
      halt [code.to_i, {'TEST' => '%s|%s' % [body, code]}, body]
      raise 'this shit should not be happen'
    end

    rewrite /\/context_sensitive\/(.*)/ do |name|
      if request.user_agent =~ /google/
        permanent_redirect route(:news, name)
      else
        redirect route(:news, name)
      end
    end

    def articles *args
      raise 'this action should never be executed'
    end

    def old_news *args
      raise 'this action should never be executed'
    end

    def old_pages *args
      raise 'this action should never be executed'
    end

    def test_pass *args
      [args, params].flatten.inspect
    end

    def news name
      [name, params].inspect
    end

    def page
      params.inspect
    end
  end

  class Store < Appetite
    map '/'

    def buy product
      [product, params]
    end
  end
  Store.to_app!

  Spec.new Cms do

    def redirected? response, status = 302
      check(response.status) == status
    end

    Testing :redirect do
      page, product = rand(1000000).to_s, rand(1000000).to_s
      get '/landing-page/%s/%s' % [page, product]
      was(last_response).redirected?
      is(last_response.header['Location']).eql? Store.route(:buy, product, :page => page)

      var = rand 1000000
      get '/articles/%s.html' % var
      was(last_response).redirected?
      is(last_response.header['Location']).eql? '/page?title=%s' % var

      var = rand.to_s
      get '/News/%s.php' % var
      was(last_response).redirected?
      is(last_response.header['Location']).eql? '/news/%s/' % var

      var, val = rand.to_s, rand.to_s
      get '/News/%s.php' % var, var => val
      was(last_response).redirected?
      is(last_response.header['Location']) == '/news/%s/?%s=%s' % [var, var, val]

      var = rand.to_s
      get '/old_news/%s.php' % var
      was(last_response).redirected? 301
      is(last_response.header['Location']) == '/news/%s' % var

      name, id = rand(1000000), rand(100000)
      get '/pages/%s-%s.html' % [name, id]
      was(last_response).redirected?
      is(last_response.header['Location']) == '/page/%s?id=%s' % [name, id]

      name, id = rand(1000000), rand(100000)
      get '/old_pages/%s-%s.html' % [name, id]
      was(last_response).redirected? 301
      is(last_response.header['Location']) == '/page?name=%s&id=%s' % [name, id]
    end

    Testing :pass do

      name = rand(100000).to_s
      response = get '/pass_test_I/%s' % name
      if ::AppetiteUtils::RESPOND_TO__PARAMETERS
        is(response.status) == 200
        is(response.body) == [name, {'name' => name}].inspect
      else
        Should 'return 404 cause splat params does not work on Appetite running on ruby1.8' do
          is(response.status) == 404
          is(response.body) == 'max params accepted: 0; params given: 1'
        end
      end

      name = rand(100000).to_s
      response = get '/pass_test_II/%s' % name
      is(response.status) == 200
      is(response.body) == [name, {'name' => name}].to_s
    end

    Testing :halt do

      body, code = rand(100000).to_s, 500
      response = get '/halt_test_I/%s/%s' % [body, code]
      expect(response.status) == code
      expect(response.body) == body
      expect(response.headers['TEST']) == '%s|%s' % [body, code]

      body, code = rand(100000).to_s, 500
      response = get '/halt_test_II/%s/%s' % [body, code]
      expect(response.status) == code
      expect(response.body) == body
      expect(response.headers['TEST']) == '%s|%s' % [body, code]
    end

    Testing :context do

      name = rand(100000).to_s
      get '/context_sensitive/%s' % name
      was(last_response).redirected?
      follow_redirect!
      is?(last_response.status) == 200
      is?(last_response.body) == [name, {}].inspect

      header['User-Agent'] = 'google'
      get '/context_sensitive/%s' % name
      was(last_response).redirected? 301
      follow_redirect!
      is?(last_response.status) == 200
      is?(last_response.body) == [name, {}].inspect
    end

  end
end
