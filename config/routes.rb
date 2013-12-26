Fluctus::Application.routes.draw do
  resources :institutions do
    resources :intellectual_objects, only: [:index], path: 'objects'
  end
  resources :intellectual_objects, only: [:show, :edit, :update], path: 'objects'

  resources :users
  resources :generic_files, except: [:destroy, :index, :new, :edit]

  Blacklight.add_routes(self)

  HydraHead.add_routes(self)

  devise_for :users, path_names: {sign_in: "login", sign_out: "logout"},
        controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  mount Hydra::RoleManagement::Engine => '/'

  devise_scope :user do
    # root to: "home#index"
    delete 'sign_out', :to => 'devise/sessions#destroy', as: :destroy_user_session
  end

  authenticated :user do
    root to: "institutions#show", as: 'authenticated_root'
    # Rails 4 users must specify the 'as' option to give it a unique name
    # root :to => "main#dashboard", :as => "authenticated_root"
  end

  root :to => "catalog#index"
end
