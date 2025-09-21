require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  setup do
    @provider = providers(:one)
    @client = clients(:one)
    @valid_appointment = appointments(:one)
  end

  test "appointment must be within provider's available hours" do
    @valid_appointment.starts_at = "2025-09-22T08:00:00-07:00"
    @valid_appointment.ends_at = "2025-09-22T08:30:00-07:00"
    appointment = Appointment.new(@valid_appointment.attributes.reject { |k, v| k == "id" })
    refute appointment.valid?
    assert_includes appointment.errors[:base], "Appointment must be within provider's available hours"
  end

  test "appointment can be exactly within availability window" do
    @valid_appointment.starts_at = "2025-09-22T09:45:00-07:00"
    @valid_appointment.ends_at = "2025-09-22T10:15:00-07:00"
    appointment = Appointment.new(@valid_appointment.attributes.reject { |k, v| k == "id" })
    assert appointment.valid?
  end

  test "appointment cannot exceed availability window" do
    @valid_appointment.starts_at = "2025-09-22T09:00:00-07:00"
    @valid_appointment.ends_at = "2025-09-22T09:45:00-07:00"  # Extends beyond 09:30
    appointment = Appointment.new(@valid_appointment.attributes.reject { |k, v| k == "id" })
    refute appointment.valid?
    assert_includes appointment.errors[:base], "Appointment must be within provider's available hours"
  end

  test "cannot book overlapping appointments for same provider" do
    overlapping_appointment = Appointment.new(@valid_appointment.attributes.reject { |k, v| k == "id" })

    refute overlapping_appointment.valid?
    assert_includes overlapping_appointment.errors[:base], "Appointment conflicts with existing booking"
  end

  test "overlapping validation ignores canceled appointments" do
    @valid_appointment.soft_cancel!

    new_appointment = Appointment.new(@valid_appointment.attributes.reject { |k, v| k == "id" }.merge(
      status: :scheduled
    ))

    assert new_appointment.valid?
  end

  test "soft_cancel! marks appointment as canceled and sets canceled_at" do
    freeze_time = Time.current
    travel_to freeze_time do
      @valid_appointment.soft_cancel!
    end

    @valid_appointment.reload
    assert @valid_appointment.canceled?
    assert_equal freeze_time.to_i, @valid_appointment.canceled_at.to_i
  end

  test "soft_cancel! doesn't delete the record" do
    appointment_id = @valid_appointment.id

    @valid_appointment.soft_cancel!

    assert Appointment.exists?(appointment_id)
    assert Appointment.find(appointment_id).canceled?
  end
end
