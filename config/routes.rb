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

  post '/objects/:intellectual_object_identifier/files(.:format)', to: 'generic_files#create', format: 'json', intellectual_object_identifier: /[^\/]*/
  get  '/objects/:intellectual_object_identifier/files(.:format)', to: 'generic_files#index', format: 'json', intellectual_object_identifier: /[^\/]*/

  get  '/objects/:identifier', to: 'intellectual_objects#show', format: 'json', identifier: /[^\/]*/, as: 'object_by_identifier'
  put  '/objects/:identifier', to: 'intellectual_objects#update', format: 'json', identifier: /[^\/]*/, as: 'object_update_by_identifier'
  post '/objects/:intellectual_object_identifier/events(.:format)', to: 'events#create', format: 'json', intellectual_object_identifier: /[^\/]*/, as: 'events_by_object_identifier'

  get  '/files/:generic_file_identifier', to: 'generic_files#show', format: 'json', generic_file_identifier: /[^\/]*/, as: 'file_by_identifier'
  put  '/files/:generic_file_identifier', to: 'generic_files#update', format: 'json', generic_file_identifier: /[^\/]*/, as: 'file_update_by_identifier'

  # The pattern for generic_file_identifier is tricky, because we do not want it to
  # conflict with /files/:generic_file_id/events. The pattern is: non-slash characters,
  # followed by a period, followed by more non-slash characters. For example,
  # virginia.edu.bagname/data/file.txt will not conflict with urn:mace:aptrust:12345
  post '/files/:generic_file_identifier/events(.:format)', to: 'events#create', format: 'json', generic_file_identifier: /[^\/]*\.[^\/]*/, as: 'events_by_file_identifier'

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
