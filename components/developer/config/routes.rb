Developer::Engine.routes.draw do
  root to: "dashboard#index"

  constraints model: /[a-z0-9_]+/ do
    get ":model/new", to: "records#new", as: :new_record
    post ":model", to: "records#create"
    get ":model/:id/edit", to: "records#edit", as: :edit_record
    get ":model/:id", to: "records#show", as: :record
    patch ":model/:id", to: "records#update"
    put ":model/:id", to: "records#update"
    delete ":model/:id", to: "records#destroy"
    get ":model", to: "records#index", as: :records
  end
end
