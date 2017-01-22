Rails.application.routes.draw do
  devise_for :users, controllers: {registrations: 'users/registrations'}
  root 'navigation#home'
  namespace :user do
    resources :logins, only: [:show, :index, :new]
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
