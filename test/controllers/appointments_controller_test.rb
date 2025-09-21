require "test_helper"

class AppointmentsControllerTest < ActionDispatch::IntegrationTest
  test "POST /appointments creates an appointment" do
    client = clients(:one)
    provider = providers(:one)
    post "/appointments", params: { appointment: { client_id: client.id, provider_id: provider.id, starts_at: "2025-09-22T09:45:00-07:00", ends_at: "2025-09-22T10:00:00-07:00" } }
    assert_response :success

    expected_start = Time.iso8601("2025-09-22T09:45:00-07:00")
    expected_end = Time.iso8601("2025-09-22T10:00:00-07:00")

    assert_equal expected_start, Appointment.last.starts_at
    assert_equal expected_end, Appointment.last.ends_at
    assert_equal client.id, Appointment.last.client_id
    assert_equal provider.id, Appointment.last.provider_id
    assert_equal "scheduled", Appointment.last.status
    assert_nil Appointment.last.canceled_at
  end

  test "DELETE /appointments/:id cancels an appointment" do
    appointment = appointments(:one)
    delete "/appointments/#{appointment.id}"
    assert_response :success

    assert_equal "canceled", Appointment.last.status
    assert_equal Time.current.to_i, Appointment.last.canceled_at.to_i
  end
end
