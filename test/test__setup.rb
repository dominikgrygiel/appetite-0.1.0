AppetiteTest__Setup__RemoteSetup = lambda do

  path_rule 'set_by', 'remote'
  path_rule! 'overridden', 'by remote'

  setup :overridden do
    format! 'overridden_by_remote'
  end

  format :xml, :json
  setup :blah do
    format :txt
  end

end

module AppetiteTest__Setup__LocalDeploy

  class App < Appetite

    path_rule 'set_by', 'app'
    path_rule 'overridden', 'by app'

    setup :overridden do
      format 'set_by_app'
    end

    format :test_global
    setup :test_format do
      format :test_local
    end
  end

  Spec.new self do
    app App.mount(&AppetiteTest__Setup__RemoteSetup)
    map App.base_url
    get

    Testing :path_rule do
      expect(App.path_rules['set_by']) == 'app'

      Ensure 'path rule overridden by remote' do
        expect(App.path_rules['overridden']) == 'by remote'
      end
    end

    Testing :format do
      is?(App.format?) == ['.test_global']
      is?(App.format? :test_format) == ['.test_local']
      Ensure 'it is overridden by remote for :overridden action' do
        is?(App.format? :overridden) == ['.overridden_by_remote']
      end
    end

  end

end

module AppetiteTest__Setup__RemoteDeploy

  class App < Appetite

  end

  Spec.new self do
    app App.mount(&AppetiteTest__Setup__RemoteSetup)
    map App.base_url
    get

    expect(App.path_rules['set_by']) == 'remote'

    Testing :format do
      is?(App.format?) == [".xml", ".json"]
      is?(App.format? :blah) == [".txt"]
    end

  end

end
