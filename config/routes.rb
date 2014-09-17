Fluctus::Application.routes.draw do
  resources :institutions, except: [:destroy] do
    resources :intellectual_objects, only: [:index, :create], path: 'objects'
    resources :events, only: [:index]
  end

  resources :intellectual_objects, only: [:show, :edit, :update, :destroy], path: 'objects' do
    resources :generic_files, only: :create, path: 'files'
    patch 'files/:id', to: 'generic_files#update', constraints: {id: /.*/}, trailing_slash: true, format: 'json'
    resources :events, only: [:create, :index]
  end

  get 'objects/:id/restore', to: 'intellectual_objects#restore', as: :intellectual_object_restore

  resources :generic_files, path: 'files' do
    resources :events, only: [:index]
  end

  devise_for :users

  resources :users do
    patch 'update_password', on: :collection
    get 'edit_password', on: :member
    patch 'generate_api_key', on: :member
  end

  get 'users/:id/admin_password_reset', to: 'users#admin_password_reset', as: :admin_password_reset_user

  resources :generic_files, only: [:show, :destroy], path: 'files' do
    resources :events, only: [:create]
  end

  get '/itemresults/search', to: 'processed_item#search', as: :processed_item_search
  post '/itemresults/search', to: 'processed_item#search'
  get 'itemresults/', to: 'processed_item#index', as: :processed_items
  get '/itemresults/get_reviewed', to: 'processed_item#get_reviewed', as: :processed_items_get_reviewed
  get 'itemresults/:id', to: 'processed_item#show', as: :processed_item
  post '/itemresults/review_all', to: 'processed_item#review_all'
  post '/itemresults/handle_selected', to: 'processed_item#handle_selected', as: :handle_selected
  post '/itemresults/show_reviewed', to: 'processed_item#show_reviewed'

  #delete 'itemresults/:etag/:name', to: 'processed_item#destroy'


  # ----------------------------------------------------------------------
  # These routes are for the API. They allow for more liberal identifier patterns.
  # Intel Obj identifier pattern includes dots. Intel Obj id pattern does not. Same for Generic File identifiers.
  # E.g. Obj Identifier = "virginia.edu.sample_bag"; Obj Id = "28337" or "urn:mace:aptrust:28337"
  # File Identifier = "virginia.edu.sample_bag/data/file.pdf"; File Id = "28999" or "urn:mace:aptrust:28999"
  #
  # Some of these routes are named because rspec cannot find them unless we explicitly name them.
  #

  post '/api/v1/itemresults/', to: 'processed_item#create', format: 'json'
  get '/api/v1/itemresults/ingested_since/:since', to: 'processed_item#ingested_since', as: :processed_items_ingested_since
  get '/api/v1/itemresults/:etag/:name/:bag_date', to: 'processed_item#show', as: :processed_item_by_etag, name: /[^\/]*/, bag_date: /[^\/]*/
  put '/api/v1/itemresults/:id', to: 'processed_item#update', format: 'json'
  put '/api/v1/itemresults/:etag/:name/:bag_date', to: 'processed_item#update', format: 'json', name: /[^\/]*/, bag_date: /[^\/]*/
  get '/api/v1/itemresults/get_reviewed', to: 'processed_item#get_reviewed', format: 'json'
  get '/api/v1/itemresults/items_for_restore', to: 'processed_item#items_for_restore', format: 'json'
  get '/api/v1/itemresults/items_for_delete', to: 'processed_item#items_for_delete', format: 'json'

  post '/api/v1/itemresults/restoration_status/:object_identifier', to: 'processed_item#set_restoration_status', as: :item_set_restoration_status, object_identifier: /.*/
  post '/api/v1/itemresults/delete_test_items', to: 'processed_item#delete_test_items', format: 'json'


  post '/api/v1/objects/include_nested', to: 'intellectual_objects#create_from_json', format: 'json'
  post '/api/v1/objects/:intellectual_object_identifier/files(.:format)', to: 'generic_files#create', format: 'json', intellectual_object_identifier: /[^\/]*/
  get  '/api/v1/objects/:intellectual_object_identifier/files(.:format)', to: 'generic_files#index', format: 'json', intellectual_object_identifier: /[^\/]*/

  get  '/api/v1/objects/:identifier', to: 'intellectual_objects#show', format: 'json', identifier: /[^\/]*/, as: 'object_by_identifier'
  put  '/api/v1/objects/:identifier', to: 'intellectual_objects#update', format: 'json', identifier: /[^\/]*/, as: 'object_update_by_identifier'
  post '/api/v1/objects/:intellectual_object_identifier/events(.:format)', to: 'events#create', format: 'json', intellectual_object_identifier: /[^\/]*/, as: 'events_by_object_identifier'


  get  '/api/v1/files/:generic_file_identifier', to: 'generic_files#show', format: 'json', generic_file_identifier: /[^\/]*/, as: 'file_by_identifier'
  put  '/api/v1/files/:generic_file_identifier', to: 'generic_files#update', format: 'json', generic_file_identifier: /[^\/]*/, as: 'file_update_by_identifier'

  # The pattern for generic_file_identifier is tricky, because we do not want it to
  # conflict with /files/:generic_file_id/events. The pattern is: non-slash characters,
  # followed by a period, followed by more non-slash characters. For example,
  # virginia.edu.bagname/data/file.txt will not conflict with urn:mace:aptrust:12345
  post '/api/v1/files/:generic_file_identifier/events(.:format)', to: 'events#create', format: 'json', generic_file_identifier: /[^\/]*\.[^\/]*/, as: 'events_by_file_identifier'

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
