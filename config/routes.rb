Fluctus::Application.routes.draw do

  #Institution Routes
  get "institutions/", to: 'institutions#index', as: :institutions
  post "institutions/", to: 'institutions#create'
  patch "institutions/:identifier", to: 'institutions#update'
  put "institutions/:identifier", to: 'institutions#update'
  delete "institutions/:identifier", to: 'institutions#destroy'
  get "institutions/:identifier/edit", to: 'institutions#edit', as: :edit_institution
  get "institutions/:identifier/events", to: 'events#index', as: :institution_events
  get "institutions/new", to: 'institutions#new', as: :new_institution
  get "institutions/:identifier", to: 'institutions#show', as: :institution

  #resources :institutions do
  #  resources :intellectual_objects, only: [:index, :create], path: 'objects'
  #  resources :events, only: [:index]
  #end

  get "objects/institution_identifier", to: 'intellectual_objects#index', as: :institution_intellectual_objects
  post "objects/institution_identifier", to: 'intellectual_objects#create'

  resources :intellectual_objects, only: [:show, :edit, :update, :destroy], path: 'objects' do
    resources :generic_files, only: :create, path: 'files'
    patch "files/:id", to: 'generic_files#update', constraints: {id: /.*/}, trailing_slash: true, format: 'json'
    resources :events, only: [:create, :index]
  end

  devise_for :users

  resources :users do
    patch 'update_password', on: :collection
    get 'edit_password', on: :member
    patch 'generate_api_key', on: :member
  end

  resources :generic_files, only: [:show, :destroy], path: 'files' do
    resources :events, only: [:create]
  end

  Blacklight.add_routes(self)

  mount Hydra::RoleManagement::Engine => '/'

  authenticated :user do
    root to: "institutions#show", as: 'authenticated_root'
    # Rails 4 users must specify the 'as' option to give it a unique name
    # root :to => "main#dashboard", :as => "authenticated_root"
  end

  root :to => "catalog#index"
end
