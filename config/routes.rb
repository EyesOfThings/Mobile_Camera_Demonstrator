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
  post "/upload_feed_to_db", to: "home#upload_feed_to_db"
  delete "/delete_wizard", to: "home#delete_wizard"
  get "/load_wizards", to: "home#load_wizards"
  get "/load_animation_path", to: "home#load_animation_path"
  post "/change_animation_public", to: "home#change_animation_public"
  get "/load_public_animation_path", to: "home#load_public_animation_path"
  get "/feed" => "home#feeds"

  get "/v1/emotions" => "devices#emotions"
  get "/v1/devices/:device_id/images/" => "devices#device_images"
  get "/v1/devices/:device_id/images/b/" => "home#list_device_images"

  get "/v1/devices" => "devices#index"
  get "/v1/:email/devices" => "devices#user_devices"

  get "/v1/wizards" => "wizards#index"

  get "/v1/animations" => "animations#index"
  get "/v1/animations/public" => "animations#public"

  get '/v1/swagger' => "home#swagger"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
