require "test_helper"

class AvailabilityTest < ActiveSupport::TestCase
  setup do
    @provider = providers(:one)
  end

  test "hhmm_to_minutes converts correctly" do
    assert_equal 0,    Availability.hhmm_to_minutes("00:00")
    assert_equal 389,  Availability.hhmm_to_minutes("06:29")
    assert_equal 390,  Availability.hhmm_to_minutes("06:30")
    assert_equal 1439, Availability.hhmm_to_minutes("23:59")
  end

  test "minutes_to_hhmm converts correctly" do
    assert_equal "00:00", Availability.minutes_to_hhmm(0)
    assert_equal "06:29", Availability.minutes_to_hhmm(389)
    assert_equal "06:30", Availability.minutes_to_hhmm(390)
    assert_equal "23:59", Availability.minutes_to_hhmm(1439)
  end

  test "hhmm_to_minutes raises on invalid input" do
    [ "24:00", "12:60", "99:99", "7:00", "0700", "abc", "", nil ].each do |bad|
      assert_raises(ArgumentError) { Availability.hhmm_to_minutes(bad) }
    end
  end

  test "setters accept HH:MM and helpers return HH:MM" do
    availability = Availability.new(
      provider: @provider,
      remote_id: "t-1",
      source: "calendly",
      day_of_week: :monday
    )

    availability.starts_at = "09:00"
    availability.ends_at   = "09:30"

    assert_equal 540, availability.starts_at_minute
    assert_equal 570, availability.ends_at_minute
    assert_equal "09:00", availability.starts_at_hhmm
    assert_equal "09:30", availability.ends_at_hhmm
  end

  test "valid when start < end" do
    a = Availability.new(
      provider: @provider,
      remote_id: "ok-1",
      source: "calendly",
      day_of_week: :monday,
      starts_at_minute: 540, # 09:00
      ends_at_minute:   570  # 09:30
    )
    assert a.valid?, a.errors.full_messages.to_sentence
  end

  test "invalid when start == end" do
    a = Availability.new(
      provider: @provider,
      remote_id: "eq-1",
      source: "calendly",
      day_of_week: :monday,
      starts_at_minute: 540,
      ends_at_minute:   540
    )
    assert a.invalid?
    assert_includes a.errors[:base], "starts_at must be before ends_at"
  end

  test "invalid when start > end" do
    a = Availability.new(
      provider: @provider,
      remote_id: "inv-1",
      source: "calendly",
      day_of_week: :monday,
      starts_at_minute: 570, # 09:30
      ends_at_minute:   540  # 09:00
    )
    assert a.invalid?
    assert_includes a.errors[:base], "starts_at must be before ends_at"
  end
end
