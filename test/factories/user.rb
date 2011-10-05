Factory.define :user do |user|
  user.sequence(:email) { |n| "foo#{n}@example.com" }
  user.password "1234567"
  user.encrypted_password "pw"
  user.password_salt "NaCl"
  user.association :tenant
  user.first_name "Joe"
  user.last_name "Blow"
  user.confirmed_at { 2.days.ago }
end

Factory.define :admin, :parent => :user do |user|
  user.roles_mask 2
end

Factory.define :superuser, :parent => :user do |user|
  user.roles_mask 1

end
