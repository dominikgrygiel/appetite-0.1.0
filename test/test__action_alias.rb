module AppetiteTest__ActionAlias

  class AnyRequestMethod < Appetite

    action_alias 'some-url', :endpoint
    action_alias 'some-another/url', :endpoint

    def index
    end

    def endpoint
    end
  end

  class SpecificRequestMethod < Appetite

    action_alias 'some-url', :get_endpoint
    action_alias 'some-another/url', :get_endpoint

    def index
    end

    def get_endpoint
    end
  end

  class PrivateZone < Appetite

    action_alias 'some-url', :endpoint
    action_alias 'some-another/url', :endpoint

    def index
    end

    private
    def endpoint
    end
  end

  Spec.new AnyRequestMethod do

    ['endpoint', 'some-url', 'some-another/url'].each do |url|
      get url
      expect(last_response.status) == 200

      post url
      expect(last_response.status) == 200
    end

    get '/blah'
    expect(last_response.status) == 404

  end

  Spec.new SpecificRequestMethod do

    ['endpoint', 'some-url', 'some-another/url'].each do |url|
      get url
      expect(last_response.status) == 200

      post url
      expect(last_response.status) == 404
    end

    get '/blah'
    expect(last_response.status) == 404

  end
  
  Spec.new PrivateZone do

    ['some-url', 'some-another/url'].each do |url|
      get url
      expect(last_response.status) == 200

      post
      expect(last_response.status) == 200
    end

    get '/endpoint'
    expect(last_response.status) == 404

    get '/blah'
    expect(last_response.status) == 404

  end

end
