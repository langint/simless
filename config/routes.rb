Rails.application.routes.draw do
  
  root 'simulation#index'
  resources :simulation do
    get 'start_interception', on: :collection
    get 'refresh_sim', on: :collection
  end
  resources :settings
  resources :analytics
  resources :text911
  resources :api do
    post 'new_session', on: :collection
    post 'recent_calls', on: :collection
  end
  get '/connections' => 'simulation#connections'
  post  '/connections' => 'simulation#save_connections'
  get '/change_tab' => 'simulation#change_tab'
  get '/settings' => 'simulation#settings'
  get '/system_status' => 'simulation#system_status'
#  resources :backend
get '/landing' => 'simulation#landing'
end
