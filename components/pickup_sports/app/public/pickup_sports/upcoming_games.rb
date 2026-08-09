module PickupSports
  module UpcomingGames
    GameSummary = Data.define(
      :id, :title, :sport, :neighborhood, :venue, :starts_at, :capacity, :joined_count, :waitlisted_count, :host_id
    )

    module_function

    def call(limit: 20)
      Game.upcoming.includes(:roster_entries).limit(limit).map do |game|
        GameSummary.new(
          id: game.id,
          title: game.title,
          sport: game.sport,
          neighborhood: game.neighborhood,
          venue: game.venue,
          starts_at: game.starts_at,
          capacity: game.capacity,
          joined_count: game.joined_count,
          waitlisted_count: game.waitlisted_count,
          host_id: game.host_id
        )
      end
    end
  end
end
