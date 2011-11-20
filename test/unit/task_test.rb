require 'test_helper'

class TaskTest < ActiveSupport::TestCase
  context "static functions on a task" do
    should "parse hours" do
      test_hour_parse 10, 8, "8/10 a test", false, false
      test_hour_parse 10, 8, "8.0/10.0 a test", false, false
      test_hour_parse 10, 0, "0/10 a test", false, false
      test_hour_parse 0.75, 0.1, ".1/.75 a test", false, false
      test_hour_parse 0.75, 0.1, "0.1/0.75 a test", false, false
      test_hour_parse 10, 0, "8/10 a test", false, true
      test_hour_parse 0, 0, "a test", false, false
      test_hour_parse 0, 0, "a test", false, true
      test_hour_parse 0, 0, "/a test", false, false
      test_hour_parse 10, 8, "8/10:a test", false, false
      test_hour_parse 10, 8, "8/10: a test", false, false
      test_hour_parse 10, 8, "8/10 - a test", false, false
      test_hour_parse 10, 8, "8/10a test", false, false
      test_hour_parse 10, 8, "8/10 a test [qa]", true, false
      test_hour_parse 10, 8, "8/10 a [qa] test", true, false
      test_hour_parse 10, 8, "8/10 [qa] a test ", true, false
    end
  end

  def test_hour_parse total_hours, remaining_hours, description, is_qa, completed
    _total_hours, _remaining_hours, _description, _is_qa = Task.parse_hours description, completed
    assert_equal total_hours, _total_hours
    assert_equal remaining_hours, _remaining_hours
    assert_equal description, _description
    assert_equal is_qa, _is_qa
  end
end
