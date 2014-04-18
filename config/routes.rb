Fluctus::Application.routes.draw do

  #Institution Routes
  institution_ptrn = /(\w+\.)*\w+(\.edu|\.com|\.org)/
  get "institutions/", to: 'institutions#index', as: :institutions
  post "institutions/", to: 'institutions#create'
  patch "institutions/:institution_identifier", to: 'institutions#update', :constraints => { :institution_identifier => institution_ptrn }
  put "institutions/:institution_identifier", to: 'institutions#update', :constraints => { :institution_identifier => institution_ptrn }
  delete "institutions/:institution_identifier", to: 'institutions#destroy', :constraints => { :institution_identifier => institution_ptrn }
  get "institutions/:institution_identifier/edit", to: 'institutions#edit', as: :edit_institution, :constraints => { :institution_identifier => institution_ptrn }
  get "institutions/:institution_identifier/events", to: 'events#index', as: :institution_events, :constraints => { :institution_identifier => institution_ptrn }
  get "institutions/new", to: 'institutions#new', as: :new_institution
  get "institutions/:institution_identifier", to: 'institutions#show', as: :institution, :constraints => { :institution_identifier => institution_ptrn }

  #Intellectual Object Routes
  object_identifier_ptrn = /(\w+\.)*\w+(\.edu|\.com|\.org)\/[\w\-\.]+/
  get "objects/:institution_identifier", to: 'intellectual_objects#index', as: :institution_intellectual_objects, :constraints => { :institution_identifier => institution_ptrn }
  post "objects/:institution_identifier", to: 'intellectual_objects#create', :constraints => { :institution_identifier => institution_ptrn }

  get "objects/:intellectual_object_identifier", to: 'intellectual_objects#show', as: :intellectual_object, :constraints => { :intellectual_object_identifier => object_identifier_ptrn }
  patch "objects/:intellectual_object_identifier", to: 'intellectual_objects#update', :constraints => { :intellectual_object_identifier => object_identifier_ptrn }
  put "objects/:intellectual_object_identifier", to: 'intellectual_objects#update', :constraints => { :intellectual_object_identifier => object_identifier_ptrn }
  delete "objects/:intellectual_object_identifier", to: 'intellectual_objects#destroy', :constraints => { :intellectual_object_identifier => object_identifier_ptrn }
  get "objects/:intellectual_object_identifier/edit", to: 'intellectual_objects#edit', as: :edit_intellectual_object, :constraints => { :intellectual_object_identifier => object_identifier_ptrn }
  get "objects/:intellectual_object_identifier/events", to: 'events#index', as: :intellectual_object_events, :constraints => { :intellectual_object_identifier => object_identifier_ptrn }
  post "objects/:intellectual_object_identifier/events", to: 'events#create', :constraints => { :intellectual_object_identifier => object_identifier_ptrn }

  #post "objects/institution_identifier/:intellectual_object_identifier/data", to: 'generic_files#create', as: intellectual_object_generic_files, :constraints => { :institution_identifier => institution_ptrn, :intellectual_object_identifier => object_identifier_ptrn }
  #patch "objects/institution_identifier/:intellectual_object_identifier/data/:filename", to: 'generic_files#update', :constraints => { :institution_identifier => institution_ptrn, :intellectual_object_identifier => object_identifier_ptrn }

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
