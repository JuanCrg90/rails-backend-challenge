# frozen_string_literal: true

class AvailabilitySync
  SOURCE = "calendly".freeze

  def initialize(client: CalendlyClient.new)
    @client = client
  end

  # Syncs availabilities for a provider based on the Calendly feed.
  # Returns how many rows were upserted.
  def call(provider_id:)
    slots = client.fetch_slots(provider_id)
    rows  = slots.flat_map { |slot| build_rows_for_slot(provider_id, slot) }
    return 0 if rows.empty?

    Availability.upsert_all(rows, unique_by: %i[provider_id remote_id source])
    rows.size
  end

  private

  attr_reader :client

  def build_rows_for_slot(provider_id, slot)
    id = slot.fetch("id")
    start_day_of_week = day_to_sym(slot.dig("starts_at", "day_of_week"))
    end_day_of_week = day_to_sym(slot.dig("ends_at", "day_of_week"))
    start_min = Availability.hhmm_to_minutes(slot.dig("starts_at", "time"))
    end_min = Availability.hhmm_to_minutes(slot.dig("ends_at", "time"))

    if start_day_of_week == end_day_of_week
      return [] unless start_min < end_min
      [ row(provider_id, id, start_day_of_week, start_min, end_min) ]
    else
      # Cross-midnight: split into two same-day rows
      first  = row(provider_id, "#{id}-#{start_day_of_week}", start_day_of_week, start_min, 1440)
      second = row(provider_id, "#{id}-#{end_day_of_week}", end_day_of_week, 0, end_min)
      [ first, second ].select { |r| r[:starts_at_minute] < r[:ends_at_minute] }
    end
  end

  def row(provider_id, remote_id, day_sym, start_min, end_min)
    {
      provider_id: provider_id,
      remote_id: remote_id,
      source: SOURCE,
      day_of_week: Availability.day_of_weeks.fetch(day_sym),
      starts_at_minute: start_min,
      ends_at_minute: end_min,
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  def day_to_sym(str)
    str.to_s.strip.downcase.to_sym
  end
end
