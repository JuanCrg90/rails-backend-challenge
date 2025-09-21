class AvailabilitySearch
  DEFAULT_TZ = "America/Los_Angeles".freeze

  def initialize(provider:, timezone: nil)
    @provider = provider
    @timezone = (timezone.presence || DEFAULT_TZ)
    @zone     = ActiveSupport::TimeZone[@timezone] || ActiveSupport::TimeZone["UTC"]
  end

  # Returns an array of concrete availability occurrences within [from..to)
  # Params:
  # - from, to: String or Time/DateTime; ISO8601 or local time strings accepted
  #
  # Each occurrence:
  # {
  #   availability_id: Integer,
  #   remote_id: String,
  #   day_of_week: Symbol,     # e.g., :monday
  #   start: String,           # ISO8601
  #   end: String,             # ISO8601
  #   start_hhmm: String,      # "HH:MM"
  #   end_hhmm: String         # "HH:MM"
  # }
  def call(from:, to:)
    from_t = parse_time!(from, :from)
    to_t   = parse_time!(to, :to)
    raise ArgumentError, "from must be before to" if from_t >= to_t

    days = (from_t.to_date..to_t.to_date).map(&:wday).uniq
    slots = Availability.where(provider_id: provider.id, day_of_week: days)

    expand_occurrences(slots, from: from_t, to: to_t)
  end

  # Returns availability windows with booked appointments subtracted
  def free_slots(from:, to:)
    all_slots = call(from: from, to: to)
    appointments = provider.appointments.active.overlapping(
      parse_time!(from, :from),
      parse_time!(to, :to)
    )

    subtract_appointments(all_slots, appointments)
  end

  private

  attr_reader :provider, :timezone, :zone

  def parse_time!(raw, name)
    raise ArgumentError, "#{name} is required" if raw.blank?

    str = raw.is_a?(String) ? raw : raw.to_s
    # If string has a timezone/offset, prefer Time.iso8601; else treat as local in provider TZ.
    if str =~ /[zZ]|[+\-]\d{2}:\d{2}/
      Time.iso8601(str)
    else
      zone.parse(str) || Time.iso8601(str)
    end
  rescue ArgumentError
    raise ArgumentError, "invalid #{name} datetime"
  end

  def expand_occurrences(slots, from:, to:)
    # Normalize the window to the provider's timezone to avoid ambiguity
    from_in_zone = from.in_time_zone(zone)
    to_in_zone   = to.in_time_zone(zone)

    (from_in_zone.to_date..to_in_zone.to_date).flat_map do |date|
      weekday   = date.wday
      day_start = zone.local(date.year, date.month, date.day, 0, 0, 0)

      # s.day_of_week is already the enum integer (0..6); compare directly
      slots.select { |s| Availability.day_of_weeks.fetch(s.day_of_week.to_sym) == weekday }.filter_map do |slot|
        start_datetime = day_start + slot.starts_at_minute.minutes
        end_datetime   = day_start + slot.ends_at_minute.minutes

        # Intersect with [from, to)
        next if end_datetime <= from_in_zone || start_datetime >= to_in_zone

        {
          availability_id: slot.id,
          remote_id: slot.remote_id,
          day_of_week: slot.day_of_week.to_sym,
          start: [ start_datetime, from_in_zone ].max.iso8601,
          end:   [ end_datetime,   to_in_zone ].min.iso8601,
          start_hhmm: slot.starts_at_hhmm,
          end_hhmm:   slot.ends_at_hhmm
        }
      end
    end
  end

  def subtract_appointments(slots, appointments)
    slots.flat_map do |slot|
      slot_start = Time.iso8601(slot[:start])
      slot_end = Time.iso8601(slot[:end])

      # Find appointments that overlap this slot
      overlapping = appointments.select do |apt|
        apt.starts_at < slot_end && apt.ends_at > slot_start
      end

      if overlapping.empty?
        [slot]  # No conflicts, return original slot
      else
        # Split slot around appointments
        split_slot_around_appointments(slot, slot_start, slot_end, overlapping)
      end
    end.compact
  end

  def split_slot_around_appointments(original_slot, slot_start, slot_end, appointments)
    free_periods = []
    current_start = slot_start

    # Sort appointments by start time
    sorted_appointments = appointments.sort_by(&:starts_at)

    sorted_appointments.each do |appointment|
      apt_start = [appointment.starts_at, slot_start].max
      apt_end = [appointment.ends_at, slot_end].min

      # Add free period before this appointment
      if current_start < apt_start
        free_periods << build_slot_from_times(original_slot, current_start, apt_start)
      end

      # Move current_start past this appointment
      current_start = [apt_end, current_start].max
    end

    # Add remaining free period after last appointment
    if current_start < slot_end
      free_periods << build_slot_from_times(original_slot, current_start, slot_end)
    end

    free_periods
  end

  def build_slot_from_times(original_slot, starts_at, ends_at)
    original_slot.merge(
      start: starts_at.iso8601,
      end: ends_at.iso8601
    )
  end
end
