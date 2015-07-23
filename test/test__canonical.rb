module AppetiteTest__Canonical

  class App < Appetite
    map '/', '/cms', '/pages'

    def index
      rq.path
    end

    def post_eatme
      rq.path
    end

  end

  Spec.new App do

    Testing :base_url do
      get :index
      expect(last_response.status) == 200
      is?(last_response.body) == '/index'

      get
      expect(last_response.status) == 200
      is?(last_response.body) == '/'

      post :eatme
      expect(last_response.status) == 200
      is?(last_response.body) == '/eatme'
    end

    Testing :controller_canonicals do
      get :cms, :index
      expect(last_response.status) == 200
      is?(last_response.body) == '/cms/index'

      get :cms
      expect(last_response.status) == 200
      is?(last_response.body) == '/cms'

      post :cms, :eatme
      expect(last_response.status) == 200
      is?(last_response.body) == '/cms/eatme'

      get :pages, :index
      expect(last_response.status) == 200
      is?(last_response.body) == '/pages/index'

      get :pages
      expect(last_response.status) == 200
      is?(last_response.body) == '/pages'

      post :pages, :eatme
      expect(last_response.status) == 200
      is?(last_response.body) == '/pages/eatme'
    end

  end
end
