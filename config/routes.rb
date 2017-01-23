Rails.application.routes.draw do
  devise_for :users, controllers: {registrations: 'users/registrations'}
  root 'navigation#home'
  namespace :user do
    resources :logins, only: [:index, :new, :create, :destroy] do
      resources :accounts, only: [:index] do
        resources :transactions, only: [:index]
      end
    end
    put 'logins/:id/refresh' => 'logins#refresh', as: 'login_refresh'
    get 'logins/:id/reconnect' => 'logins#reconnect', as: 'login_reconnect'
    put 'logins/:id/reconnect' => 'logins#request_reconnection', as: 'login_reconnection'
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
