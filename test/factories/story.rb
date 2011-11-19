FactoryGirl.define do

  factory :feature, :class => Story do
    pivotal_identifier 123456
    story_type "feature"
    url "http://this/that/1234"
    points 5
    status "started"
    sequence(:name) { |n| "this is a test #{n}" }
    owner "Bob"
    sort 10
    body "This is some long description"
    sequence(:story_number) { |n| "S#{n}" }
    iteration
  end
end
