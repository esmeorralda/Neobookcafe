require "test_helper"

class FiltersControllerTest < ActionDispatch::IntegrationTest
  test "should get check" do
    get filters_check_url
    assert_response :success
  end
end
