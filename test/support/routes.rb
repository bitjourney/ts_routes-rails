class DashboardEngine < Rails::Engine
end

class HelloWorldEngine
  def self.call(_env)
    [200, {}, ["Hello, World!"]]
  end
end

DashboardEngine.routes.draw do
  root to: "dashboard#root"
  resources :resources
end

App.routes.draw do

  mount HelloWorldEngine => :hello, as: :hello

  mount DashboardEngine => "/dashboard", as: :dashboard_app

  root to: 'root#index'

  concern :likable do
    defaults format: :json do
      get :liked_users
      post :like
      delete :unlike
    end
  end

  resources :entries do
    concerns :likable
    resources :revisions, only: :show, controller: 'entries/revisions' do
      get :latest, on: :collection
    end
  end

  get '/photos/*timestamp(/:id)', to: 'photos#show', as: :photos

  get '/settings(/account)', to: 'settings#foo', as: :settings

  namespace :admin do
    resources :users
  end
end
