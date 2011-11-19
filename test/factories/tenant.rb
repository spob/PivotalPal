FactoryGirl.define do
  factory :tenant do
    sequence(:name) {|n| "tenant #{n}"}
    api_key = "asfasfsd"
    refresh_frequency_hours 1
  end
end
