require 'test_helper'

class StoryTest < ActiveSupport::TestCase
  context "a story" do
    setup do
      @story = FactoryGirl.build(:feature)
      assert_not_nil @story
      assert_not_nil @story.iteration
      assert_not_nil @story.iteration.project
    end

    should "parse out the story number" do
      test_story_parse("S4", " this is a test")
      test_story_parse("S4", ": this is a test")
      test_story_parse("S4", "- this is a test")
      test_story_parse("S4", " - this is a test")
      test_story_parse("R4", " - this is a test")
      test_story_parse("C4", " - this is a test")
      test_story_parse("B4", " - this is a test")
      test_story_parse("", "this is a test")
      test_story_parse("", " this is a test")
    end
  end

  def test_story_parse story_number, description
    _story_name = "#{story_number}#{description}"
    puts "Story: #{_story_name}"
    @story.name = _story_name
    @story.parse_story_name
    if story_number.empty?
      assert_nil @story.parse_story_number
    else
      assert_equal story_number, @story.parse_story_number
    end
    assert_equal description.strip, @story.parse_story_name
  end
end
