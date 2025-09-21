require "test_helper"

class Providers::AvailabilitiesControllerTest < ActionDispatch::IntegrationTest
  fixtures :providers, :availabilities

  test "GET /providers/:provider_id/availabilities returns occurrences" do
    provider = providers(:one)
    from = "2025-09-22T06:00:00-05:00"
    to   = "2025-09-22T12:00:00-05:00"

    get "/providers/#{provider.id}/availabilities", params: { from:, to: }
    assert_response :success

    body = JSON.parse(response.body)
    assert body.is_a?(Array)
    refute_empty body
    assert_includes body.first.keys, "start"
    assert_includes body.first.keys, "end"
  end

  test "404 when provider does not exist" do
    get "/providers/999999/availabilities", params: { from: "2025-09-22T09:00:00Z", to: "2025-09-22T10:00:00Z" }
    assert_response :not_found
    body = JSON.parse(response.body)
    assert_equal "provider not found", body["error"]
  end

  test "422 when 'from' is missing" do
    provider = providers(:one)
    get "/providers/#{provider.id}/availabilities", params: { to: "2025-09-22T10:00:00Z" }
    assert_response :unprocessable_content
    body = JSON.parse(response.body)
    assert_includes body["error"], "from"
  end

  test "422 when 'to' is missing" do
    provider = providers(:one)
    get "/providers/#{provider.id}/availabilities", params: { from: "2025-09-22T09:00:00Z" }
    assert_response :unprocessable_content
    body = JSON.parse(response.body)
    assert_includes body["error"], "to"
  end

  test "422 when datetimes are invalid" do
    provider = providers(:one)
    get "/providers/#{provider.id}/availabilities", params: { from: "not-a-time", to: "2025-09-22T10:00:00Z" }
    assert_response :unprocessable_content
    body1 = JSON.parse(response.body)
    assert_includes body1["error"], "invalid from"

    get "/providers/#{provider.id}/availabilities", params: { from: "2025-09-22T09:00:00Z", to: "nope" }
    assert_response :unprocessable_content
    body2 = JSON.parse(response.body)
    assert_includes body2["error"], "invalid to"
  end

  test "422 when from is not before to" do
    provider = providers(:one)

    get "/providers/#{provider.id}/availabilities", params: { from: "2025-09-22T10:00:00Z", to: "2025-09-22T10:00:00Z" }
    assert_response :unprocessable_content
    body1 = JSON.parse(response.body)
    assert_includes body1["error"], "from must be before to"

    get "/providers/#{provider.id}/availabilities", params: { from: "2025-09-22T11:00:00Z", to: "2025-09-22T10:00:00Z" }
    assert_response :unprocessable_content
    body2 = JSON.parse(response.body)
    assert_includes body2["error"], "from must be before to"
  end
end
