require "json"

namespace :events do
  desc "Ingest events from JSON feed file(s) into the deterministic, deduplicated store. " \
       "Usage: rake events:ingest            (reads db/events_feed/*.json)        " \
       "rake events:ingest[path.json] (reads one file or a glob)"
  task :ingest, [:path] => :environment do |_t, args|
    glob = args[:path].presence || Rails.root.join("db/events_feed/*.json").to_s
    files = Dir.glob(glob)

    if files.empty?
      warn "events:ingest — no feed files matched #{glob}"
      next
    end

    totals = { created: 0, updated: 0, skipped: 0, errors: 0 }

    files.each do |file|
      records = load_records(file)
      result = Events::Ingest.call(records)
      totals[:created] += result.created
      totals[:updated] += result.updated
      totals[:skipped] += result.skipped
      totals[:errors]  += result.errors.size
      result.errors.each do |e|
        warn "  ! #{File.basename(file)}[#{e[:index]}] #{e[:title]}: #{e[:messages].join(', ')}"
      end
      puts "  #{File.basename(file)}: +#{result.created} created, #{result.updated} updated, #{result.skipped} skipped"
    end

    puts "events:ingest done — #{totals[:created]} created, #{totals[:updated]} updated, " \
         "#{totals[:skipped]} skipped, #{totals[:errors]} errored across #{files.size} file(s)."
  end
end

# A feed file is either a bare JSON array of event objects, or an object with an
# "events" key holding that array. Anything else is treated as empty.
def load_records(file)
  data = JSON.parse(File.read(file))
  case data
  when Array then data
  when Hash  then data["events"] || data[:events] || []
  else []
  end
rescue JSON::ParserError => e
  warn "  ! #{File.basename(file)}: invalid JSON (#{e.message})"
  []
end
