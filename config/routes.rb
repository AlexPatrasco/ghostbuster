Rails.application.routes.draw do
  devise_for :users, controllers: {registrations: 'users/registrations'}
  root 'navigation#home'
  namespace :user do
    get 'logins' => 'logins#index'
    get 'logins/new' => 'logins#add_login', as: :new_login
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
