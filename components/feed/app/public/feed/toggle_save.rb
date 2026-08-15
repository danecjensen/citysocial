module Feed
  module ToggleSave
    module_function

    def call(post:, user_id:)
      state = nil
      post.with_lock do
        save = post.saves.find_by(user_id: user_id)
        if save
          save.destroy!
          state = :removed
        else
          post.saves.create!(user_id: user_id)
          state = :saved
        end
      end

      PlatformCore::EventBus.publish("feed.save_changed", post_id: post.id, user_id: user_id, state: state)
      state
    end
  end
end
