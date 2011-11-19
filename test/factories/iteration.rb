FactoryGirl.define do
  factory :iteration do
    sequence(:iteration_number) { |n| n }
    start_on { 3.days.since }
    end_on { 7.days.ago }
    last_synced_at { 5.minutes.ago }
    project
  end
end
