Marketplace::Engine.routes.draw do
  # The engine is mounted at /marketplace, so the listings resource lives at the
  # engine root (path: "") to avoid a doubled /marketplace/listings path.
  resources :listings, path: "", param: :slug do
    member do
      post :mark_sold
    end
    collection do
      get :mine
    end
  end
end
