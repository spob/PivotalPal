Factory.sequence :name do |n|
  "tenant_name#{n}"
end

Factory.define :tenant do |tenant|
  tenant.name { Factory.next(:name) }
end
