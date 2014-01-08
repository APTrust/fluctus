Fluctus::Application.routes.draw do
  resources :institutions do
    resources :intellectual_objects, only: [:index, :create], path: 'objects'
  end
  resources :intellectual_objects, only: [:show, :edit, :update, :destroy], path: 'objects' do
    resources :generic_files, only: [:create], path: 'files'
    resources :events, only: [:create]
  end

  resources :users
  resources :generic_files, only: [:show, :update, :destroy], path: 'files' do
    resources :events, only: [:create]
  end

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
