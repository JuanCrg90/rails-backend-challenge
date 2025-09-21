require "test_helper"

class AvailabilitySearchTest < ActiveSupport::TestCase
  setup do
    @provider1 = providers(:one)
    @provider2 = providers(:two)
  end

  test "requires from and to" do
    service = AvailabilitySearch.new(provider: @provider1)
    assert_raises(ArgumentError) { service.call(from: nil, to: "2025-09-22T12:00:00Z") }
    assert_raises(ArgumentError) { service.call(from: "2025-09-22T10:00:00Z", to: nil) }
  end

  test "from must be before to" do
    service = AvailabilitySearch.new(provider: @provider1)
    assert_raises(ArgumentError) { service.call(from: "2025-09-22T10:00:00Z", to: "2025-09-22T10:00:00Z") }
    assert_raises(ArgumentError) { service.call(from: "2025-09-22T11:00:00Z", to: "2025-09-22T10:00:00Z") }
  end

  test "invalid datetime strings raise" do
    service = AvailabilitySearch.new(provider: @provider1)
    assert_raises(ArgumentError) { service.call(from: "bogus", to: "2025-09-22T10:00:00Z") }
    assert_raises(ArgumentError) { service.call(from: "2025-09-22T09:00:00Z", to: "nope") }
  end

  test "returns and clips Monday occurrences within the window" do
    # This window should catch the tail of 09:00–09:30 and the start of 09:45–10:15
    from = "2025-09-22T09:20:00-07:00"
    to = "2025-09-22T10:00:00-07:00"

    results = AvailabilitySearch.new(provider: @provider1).call(from:, to:)
    ids = results.map { |r| r[:remote_id] }

    assert_includes ids, "p1-slot-morning-1"
    assert_includes ids, "p1-slot-morning-back-to-back"
    assert_equal 2, results.size

    r1 = results.find { |r| r[:remote_id] == "p1-slot-morning-1" }
    r2 = results.find { |r| r[:remote_id] == "p1-slot-morning-back-to-back" }

    # helpers show full slot; start/end are clipped to the query window
    assert_equal "09:00", r1[:start_hhmm]
    assert_equal "09:30", r1[:end_hhmm]
    assert_operator Time.iso8601(r1[:start]), :>=, Time.iso8601(from)
    assert_operator Time.iso8601(r1[:end]),   :<=, Time.iso8601(to)

    assert_equal "09:45", r2[:start_hhmm]
    assert_equal "10:15", r2[:end_hhmm]
    assert_operator Time.iso8601(r2[:start]), :>=, Time.iso8601(from)
    assert_operator Time.iso8601(r2[:end]),   :<=, Time.iso8601(to)

    assert_equal :monday, r1[:day_of_week]
    assert_equal :monday, r2[:day_of_week]
  end

  test "ignores slots that belong to other providers" do
    from = "2025-09-23T10:00:00-07:00"
    to   = "2025-09-23T12:00:00-07:00"

    results = AvailabilitySearch.new(provider: @provider1).call(from:, to:)
    assert_equal 0, results.size
  end

  test "handles cross-midnight by returning occurrences on both days, clipped to window" do
    # Use naive times interpreted in America/Los_Angeles (service default)
    # Monday 23:45 → Tuesday 00:10 in LA
    from = "2025-09-22 23:45"
    to   = "2025-09-23 00:10"

    results = AvailabilitySearch.new(provider: @provider1).call(from:, to:)
    ids = results.map { |r| r[:remote_id] }

    assert_includes ids, "p1-slot-evening-cross-midnight-monday"
    assert_includes ids, "p1-slot-evening-cross-midnight-tuesday"
    assert_equal 2, results.size

    mon = results.find { |r| r[:remote_id] == "p1-slot-evening-cross-midnight-monday" }
    tue = results.find { |r| r[:remote_id] == "p1-slot-evening-cross-midnight-tuesday" }

    assert_equal "23:30", mon[:start_hhmm]
    assert_equal "24:00", mon[:end_hhmm]
    assert_operator Time.iso8601(mon[:start]), :>=, Time.iso8601("2025-09-23T06:45:00Z") # 23:45 LA == 06:45Z
    assert_operator Time.iso8601(mon[:end]),   :<=, Time.iso8601("2025-09-23T07:10:00Z") # 00:10 LA == 07:10Z

    assert_equal "00:00", tue[:start_hhmm]
    assert_equal "00:15", tue[:end_hhmm]
    assert_operator Time.iso8601(tue[:start]), :>=, Time.iso8601("2025-09-23T06:45:00Z")
    assert_operator Time.iso8601(tue[:end]),   :<=, Time.iso8601("2025-09-23T07:10:00Z")

    assert_equal :monday,  mon[:day_of_week]
    assert_equal :tuesday, tue[:day_of_week]
  end

  test "free_slots returns same as call when no appointments exist" do
    # Clear any existing appointments for clean test
    @provider1.appointments.destroy_all

    from = "2025-09-22T09:20:00-07:00"
    to = "2025-09-22T10:00:00-07:00"

    all_slots = AvailabilitySearch.new(provider: @provider1).call(from: from, to: to)
    free_slots = AvailabilitySearch.new(provider: @provider1).free_slots(from: from, to: to)

    assert_equal all_slots.size, free_slots.size
    assert_equal all_slots.map { |s| s[:remote_id] }.sort,
                 free_slots.map { |s| s[:remote_id] }.sort
  end

  test "free_slots removes slot completely when appointment exactly covers it" do
    from = "2025-09-22T09:00:00-07:00"
    to = "2025-09-22T12:00:00-07:00"

    all_slots = AvailabilitySearch.new(provider: @provider1).call(from: from, to: to)
    free_slots = AvailabilitySearch.new(provider: @provider1).free_slots(from: from, to: to)

    assert_equal all_slots.size - 1, free_slots.size

    free_remote_ids = free_slots.map { |s| s[:remote_id] }
    refute_includes free_remote_ids, "p1-slot-morning-1"

    assert_includes free_remote_ids, "p1-slot-morning-back-to-back"
  end
end
