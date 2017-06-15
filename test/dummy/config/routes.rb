App.routes.draw do
  get '/' => 'root#index'

  concern :likable do
    defaults format: :json do
      get :liked_users
      post :like
      delete :unlike
    end
  end

  resources :entries, only: %i(index new destroy) do
    concerns :likable
    resources :revisions, only: :show, controller: 'entries/revisions' do
      get :latest, on: :collection
    end
  end

  get '/photos(/:id)', to: 'photos#show'

  namespace :admin do
    resources :users
  end
end