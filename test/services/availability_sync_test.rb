require "test_helper"

class AvailabilitySyncTest < ActiveSupport::TestCase
  setup do
    @provider1 = providers(:one)
    @provider2 = providers(:two)
    @provider3 = providers(:three)
  end

  test "syncs provider 1 (same-day + cross-midnight split)" do
    processed = AvailabilitySync.new.call(provider_id: @provider1.id)
    assert_operator processed, :>, 0

    early = Availability.find_by(remote_id: "p1-slot-early-morning",
                                 provider_id: @provider1.id, source: "calendly")
    assert_not_nil early
    assert_equal 1, Availability.day_of_weeks.fetch(early.day_of_week.to_sym)
    assert_equal 390, early.starts_at_minute  # 06:30
    assert_equal 420, early.ends_at_minute    # 07:00

    # cross-midnight split
    first = Availability.find_by(remote_id: "p1-slot-evening-cross-midnight-monday",
                                 provider_id: @provider1.id)
    second = Availability.find_by(remote_id: "p1-slot-evening-cross-midnight-tuesday",
                                  provider_id: @provider1.id)
    assert_not_nil first
    assert_not_nil second
    assert_equal 1, Availability.day_of_weeks.fetch(first.day_of_week.to_sym)
    assert_equal 1410, first.starts_at_minute  # 23:30
    assert_equal 1440, first.ends_at_minute
    assert_equal 2, Availability.day_of_weeks.fetch(second.day_of_week.to_sym)
    assert_equal 0, second.starts_at_minute
    assert_equal 15, second.ends_at_minute
  end

  test "syncs provider 2 array without errors (duplicates upsert idempotently)" do
    processed = AvailabilitySync.new.call(provider_id: @provider2.id)
    assert_operator processed, :>=, 3

    short = Availability.find_by(remote_id: "p2-slot-short",
                                 provider_id: @provider2.id, source: "calendly")
    long = Availability.find_by(remote_id: "p2-slot-long",
                                 provider_id: @provider2.id, source: "calendly")
    dup = Availability.find_by(remote_id: "p2-slot-duplicate-window",
                                 provider_id: @provider2.id, source: "calendly")

    assert_not_nil short
    assert_not_nil long
    assert_not_nil dup
  end

  test "syncs provider 3 including a cross-midnight case" do
    processed = AvailabilitySync.new.call(provider_id: @provider3.id)
    assert_operator processed, :>=, 3

    isolated = Availability.find_by(remote_id: "p3-slot-isolated", provider_id: @provider3.id)
    border = Availability.find_by(remote_id: "p3-slot-border-case", provider_id: @provider3.id)
    cross1 = Availability.find_by(remote_id: "p3-slot-far-future-tuesday",  provider_id: @provider3.id)
    cross2 = Availability.find_by(remote_id: "p3-slot-far-future-wednesday", provider_id: @provider3.id)

    assert_not_nil isolated
    assert_not_nil border
    assert_not_nil cross1
    assert_not_nil cross2

    assert_equal 1380, cross1.starts_at_minute # 23:00
    assert_equal 1440, cross1.ends_at_minute
    assert_equal 0, cross2.starts_at_minute # 00:00
    assert_equal 30, cross2.ends_at_minute
  end
end
