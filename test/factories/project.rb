Factory.sequence :name do |n|
  "project_name#{n}"
end

Factory.define :project do |project|
  project.name { Factory.next(:name) }
  project.association :tenant
end
