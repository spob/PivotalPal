Factory.sequence :name do |n|
  "category_name#{n}"
end

Factory.define :category do |category|
  category.name { Factory.next(:name) }
  category.association :tenant
end
