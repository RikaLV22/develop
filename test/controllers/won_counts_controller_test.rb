require "test_helper"

class WonCountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @won_count = won_counts(:one)
  end

  test "should get index" do
    get won_counts_url, as: :json
    assert_response :success
  end

  test "should create won_count" do
    assert_difference("WonCount.count") do
      post won_counts_url, params: { won_count: { name: @won_count.name, wonCount: @won_count.wonCount } }, as: :json
    end

    assert_response :created
  end

  test "should show won_count" do
    get won_count_url(@won_count), as: :json
    assert_response :success
  end

  test "should update won_count" do
    patch won_count_url(@won_count), params: { won_count: { name: @won_count.name, wonCount: @won_count.wonCount } }, as: :json
    assert_response :success
  end

  test "should destroy won_count" do
    assert_difference("WonCount.count", -1) do
      delete won_count_url(@won_count), as: :json
    end

    assert_response :no_content
  end
end
