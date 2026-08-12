module Restaurants
  # Applies one matchup decision: locks and updates both Elo ratings and records
  # the vote atomically in one PostgreSQL round trip. Keeping this as one
  # statement matters in production, where network latency can dwarf execution
  # time for each individual query.
  module RecordMatchup
    Result = Data.define(:vote_id, :voter_id, :winner_id, :loser_id, :winner_name)

    SQL = <<~SQL.squish.freeze
      WITH locked_restaurants AS MATERIALIZED (
        SELECT id, name, elo
        FROM restaurants_restaurants
        WHERE id IN ($1, $2)
        ORDER BY id
        FOR UPDATE
      ),
      ratings AS (
        SELECT
          MAX(CASE WHEN id = $1 THEN elo END) AS winner_elo,
          MAX(CASE WHEN id = $2 THEN elo END) AS loser_elo,
          MAX(CASE WHEN id = $1 THEN name END) AS winner_name
        FROM locked_restaurants
        HAVING COUNT(*) = 2
      ),
      scored AS (
        SELECT *,
          1.0 / (1.0 + POWER(10.0, (loser_elo - winner_elo) / 400.0)) AS expected_winner
        FROM ratings
      ),
      updated_restaurants AS (
        UPDATE restaurants_restaurants AS restaurant
        SET
          elo = CASE
            WHEN restaurant.id = $1
              THEN ROUND((scored.winner_elo + (#{Elo::K} * (1.0 - scored.expected_winner)))::numeric)
            ELSE ROUND((scored.loser_elo + (#{Elo::K} * (scored.expected_winner - 1.0)))::numeric)
          END,
          matches_count = restaurant.matches_count + 1,
          updated_at = $4
        FROM scored
        WHERE restaurant.id IN ($1, $2)
        RETURNING restaurant.id
      ),
      inserted_vote AS (
        INSERT INTO restaurants_votes (voter_id, winner_id, loser_id, created_at, updated_at)
        SELECT $3, $1, $2, $4, $4
        FROM scored
        WHERE (SELECT COUNT(*) FROM updated_restaurants) = 2
        RETURNING id, voter_id, winner_id, loser_id
      )
      SELECT inserted_vote.*, scored.winner_name
      FROM inserted_vote
      CROSS JOIN scored
    SQL

    module_function

    def call(winner_id:, loser_id:, voter_id:)
      raise ArgumentError, "a restaurant cannot beat itself" if winner_id == loser_id

      row = execute(winner_id: winner_id, loser_id: loser_id, voter_id: voter_id).first
      raise ActiveRecord::RecordNotFound, "matchup restaurants not found" unless row

      result = Result.new(
        vote_id: row.fetch("id"),
        voter_id: row.fetch("voter_id"),
        winner_id: row.fetch("winner_id"),
        loser_id: row.fetch("loser_id"),
        winner_name: row.fetch("winner_name")
      )
      Restaurants::Vote.announce_created(**result.to_h.except(:winner_name))
      result
    end

    def execute(winner_id:, loser_id:, voter_id:)
      now = Time.current
      binds = [
        query_attribute("winner_id", winner_id, ActiveRecord::Type::Integer.new),
        query_attribute("loser_id", loser_id, ActiveRecord::Type::Integer.new),
        query_attribute("voter_id", voter_id, ActiveRecord::Type::Integer.new),
        query_attribute("recorded_at", now, ActiveRecord::Type::DateTime.new)
      ]
      Restaurants::ApplicationRecord.connection.exec_query(SQL, name, binds)
    end

    def query_attribute(name, value, type)
      ActiveRecord::Relation::QueryAttribute.new(name, value, type)
    end
  end
end
