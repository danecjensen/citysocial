module Restaurants
  class LeaderboardController < PlatformCore::BaseController
    before_action :require_login

    # How many recent matchup decisions the activity feed shows.
    RECENT_PICKS_LIMIT = 8

    def index
      @cuisines = Restaurants::Restaurant.cuisines
      # Only honor a cuisine that actually exists in the catalog, so an unknown
      # value falls back to the full board rather than an empty one.
      @cuisine = params[:cuisine].presence_in(@cuisines)
      @restaurants = Restaurants::Restaurant.ranked.by_cuisine(@cuisine).with_attached_photos
      @recent_picks = recent_picks
    end

    private

    # The last few community decisions as {winner:, loser:, decided_at:} rows.
    # Restaurant names are resolved in ONE batched query (not per vote) so the
    # feed stays flat as vote volume grows; a vote whose winner or loser no
    # longer exists is skipped rather than rendered blank.
    def recent_picks
      votes = Restaurants::Vote.recent.limit(RECENT_PICKS_LIMIT).to_a
      ids = votes.flat_map { |vote| [vote.winner_id, vote.loser_id] }.uniq
      by_id = Restaurants::Restaurant.where(id: ids).index_by(&:id)

      votes.filter_map do |vote|
        winner = by_id[vote.winner_id]
        loser = by_id[vote.loser_id]
        next unless winner && loser

        { winner: winner, loser: loser, decided_at: vote.created_at }
      end
    end
  end
end
