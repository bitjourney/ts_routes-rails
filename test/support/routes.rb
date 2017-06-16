App.routes.draw do
  get '/' => 'root#index', as: :root

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

  namespace :admin do
    resources :users
  end
end