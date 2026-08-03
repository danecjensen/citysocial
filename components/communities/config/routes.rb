Communities::Engine.routes.draw do
  # The engine is mounted at /communities, so the communities resource lives at
  # the engine root (path: "") to avoid a doubled /communities/communities path.
  resources :communities, path: "", only: %i[index show new create], param: :slug do
    member do
      post :join
      delete :leave
    end

    resources :posts, only: %i[show new create] do
      member do
        post :upvote
        post :downvote
      end

      resources :comments, only: %i[create] do
        member do
          post :upvote
          post :downvote
        end
      end
    end
  end
end
