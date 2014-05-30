Fluctus::Application.routes.draw do
  resources :institutions do
    resources :intellectual_objects, only: [:index, :create], path: 'objects'
    resources :events, only: [:index]
  end

  resources :intellectual_objects, only: [:show, :edit, :update, :destroy], path: 'objects' do
    resources :generic_files, only: :create, path: 'files'
    patch "files/:id", to: 'generic_files#update', constraints: {id: /.*/}, trailing_slash: true, format: 'json'
    resources :events, only: [:create, :index]
  end

  resources :generic_files, path: 'files' do
    resources :events, only: [:index]
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

  get 'itemresults/', to: 'processed_item#index', as: :processed_items
  post 'itemresults/', to: 'processed_item#create', format: 'json'
  get 'itemresults/:etag/:name/:bag_date', to: 'processed_item#show', as: :processed_item, bag_date: /.*/
  put 'itemresults/:etag/:name/:bag_date', to: 'processed_item#update', format: 'json', bag_date: /.*/
  #delete 'itemresults/:etag/:name', to: 'processed_item#destroy'

  Blacklight.add_routes(self)

  mount Hydra::RoleManagement::Engine => '/'

  authenticated :user do
    root to: "institutions#show", as: 'authenticated_root'
    # Rails 4 users must specify the 'as' option to give it a unique name
    # root :to => "main#dashboard", :as => "authenticated_root"
  end

  root :to => "catalog#index"
end
