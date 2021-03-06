# == Schema Information
#
# Table name: events
#
#  id                :integer          not null, primary key
#  event_id          :string(255)
#  type              :string(255)
#  title             :string(255)      not null
#  url               :string(255)      not null
#  description       :text(65535)
#  started_at        :datetime         not null
#  ended_at          :datetime
#  limit_number      :integer
#  address           :string(255)      not null
#  place             :string(255)      not null
#  lat               :float(24)
#  lon               :float(24)
#  attend_number     :integer          default(0), not null
#  substitute_number :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_events_on_event_id_and_type        (event_id,type) UNIQUE
#  index_events_on_started_at_and_ended_at  (started_at,ended_at)
#  index_events_on_title                    (title)
#

class Atnd < Event
  ATND_API_URL = "http://api.atnd.org/events/"
  ATND_EVENTPAGE_URL = "https://atnd.org/events/"

  def self.find_event
    http_client = HTTPClient.new
    response = http_client.get(ATND_API_URL, {keyword: "UE4よちよち勉強会", count: 100, format: :json}, {})
    return JSON.parse(response.body)
  end

  def self.import_events!
    update_columns = Atnd.column_names - ["id", "type", "shortener_url", "event_id", "created_at"]
    events_response = Atnd.find_event
    atnd_events = []
    events_response["events"].each_with_index do |res|
      event = res["event"]
      atnd_event = Atnd.new(
        event_id: event["event_id"].to_s,
        title: event["title"].to_s,
        url: ATND_EVENTPAGE_URL + event["event_id"].to_s,
        description: ApplicationRecord.basic_sanitize(event["description"].to_s),
        limit_number: event["limit"],
        address: event["address"].to_s,
        place: event["place"].to_s,
        lat: event["lat"],
        lon: event["lon"],
        attend_number: event["accepted"],
        substitute_number: event["waiting"]
      )
      atnd_event.started_at = DateTime.parse(event["started_at"])
      atnd_event.ended_at = DateTime.parse(event["ended_at"]) if event["ended_at"].present?
      atnd_events << atnd_event
    end

    Atnd.import!(atnd_events, on_duplicate_key_update: update_columns)
  end
end
