Rails.application.routes.draw do
  root "home#index"

  post "/shorten", to: "urls#create"

  get "/:short_code", to: "urls#show", constraints: {
    short_code: /[a-zA-Z0-9_-]{1,15}/
  }

  get "/analytics/:short_code", to: "analytics#show"
end
