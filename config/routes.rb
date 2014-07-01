Fluctus::Application.routes.draw do
  resources :institutions, except: [:destroy] do
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
  get 'itemresults/:id', to: 'processed_item#show', as: :processed_item
  get 'itemresults/:etag/:name/:bag_date', to: 'processed_item#show', as: :processed_item_by_etag, name: /[^\/]*/, bag_date: /[^\/]*/
  put 'itemresults/:etag/:name/:bag_date', to: 'processed_item#update', format: 'json', name: /[^\/]*/, bag_date: /[^\/]*/
  #delete 'itemresults/:etag/:name', to: 'processed_item#destroy'


  # ----------------------------------------------------------------------
  # These routes are for the API. They allow for more liberal identifier patterns.
  # Intel Obj identifier pattern includes dots. Intel Obj id pattern does not. Same for Generic File identifiers.
  # E.g. Obj Identifier = "virginia.edu.sample_bag"; Obj Id = "28337" or "urn:mace:aptrust:28337"
  # File Identifier = "virginia.edu.sample_bag/data/file.pdf"; File Id = "28999" or "urn:mace:aptrust:28999"
  #

  post '/objects/:identifier/files(.:format)', to: 'generic_files#create', format: 'json', identifier: /[^\/]*/
  get '/objects/:identifier/files(.:format)', to: 'generic_files#index', format: 'json', identifier: /[^\/]*/
  get '/objects/:identifier', to: 'intellectual_objects#show', format: 'json', identifier: /[^\/]*/
  post '/objects/:intellectual_object_identifier/events(.:format)', to: 'events#create', format: 'json', intellectual_object_identifier: /[^\/\.]*\.[^\/]*/

  get '/files/:identifier', to: 'generic_files#show', format: 'json', identifier: /[^\/]*/
  post '/files/:generic_file_identifier/events(.:format)', to: 'events#create', format: 'json', generic_file_identifier: /[^\/\.]*\.[^\/]*/

  #
  # End of API routes
  # ----------------------------------------------------------------------

  Blacklight.add_routes(self)

  mount Hydra::RoleManagement::Engine => '/'

  authenticated :user do
    root to: "institutions#show", as: 'authenticated_root'
    # Rails 4 users must specify the 'as' option to give it a unique name
    # root :to => "main#dashboard", :as => "authenticated_root"
  end

  root :to => "catalog#index"
end
