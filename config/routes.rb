Rails.application.routes.draw do
  get 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure', to: redirect('/')
  get 'signout', to: 'sessions#destroy', as: 'signout'

  resources :sessions, only: [:create, :destroy]
  resource :home, only: [:show]

  root to: "home#show"

  get "/integrations" => "home#integrations"
  get "/wizards" => "home#wizards"
  get "/notifications" => "home#notifications"
  get "/animations" => "home#animations"

  get "/send_to_seaweedFS", to: "home#send_to_seaweedfs"
  get "/send_to_DB", to: "home#send_to_db"
  post "/create_animation", to: "home#create_animation"
  post "/save_animation_path", to: "home#save_animation_path"
  post "/create_wizard", to: "home#create_wizard"
  post "/update_wizards", to: "home#update_wizards"
  delete "/delete_wizard", to: "home#delete_wizard"
  get "/load_wizards", to: "home#load_wizards"
  get "/load_animation_path", to: "home#load_animation_path"
  get "/feed/:uid" => "home#feeds"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
