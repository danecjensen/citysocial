module Feedback
  class Support < ApplicationRecord
    belongs_to :submission,
               class_name: "Feedback::Submission",
               counter_cache: true,
               inverse_of: :supports

    validates :user_id, presence: true, uniqueness: { scope: :submission_id }

    after_create_commit :publish_supported

    private

    def publish_supported
      PlatformCore::EventBus.publish(
        "feedback.submission_supported",
        submission_id: submission_id,
        supporter_id: user_id,
        author_id: submission.author_id
      )
    end
  end
end
