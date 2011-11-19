FactoryGirl.define do
  factory :project do
    sequence(:name) {|n| "Project #{n}" }
    last_synced_at 5.minutes.ago
    tenant
    pivotal_identifier 987654
    iteration_duration_weeks 2
    sync_status "ok"
    next_sync_at {1.hour.since}
    renumber_features {true}
    renumber_chores {true}
    renumber_bugs {true}
    renumber_releases {true}
    feature_prefix "S"
    chore_prefix "C"
    bug_prefix "B"
    release_prefix "R"
    time_zone "Eastern Time (US & Canada)"
  end
end
