Rails.application.routes.draw do
  post "/" => "ses_proxy#create"
  root "emails#index"
  resources :emails, only: [:show]
end
