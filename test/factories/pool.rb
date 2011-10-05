Factory.sequence :name do |n|
  "pool_name#{n}"
end

Factory.define :unlimited_pool, :class => Pool do |pool|
  pool.name { Factory.next(:name) }
  pool.association :tenant
  pool.unlimited {true}
end

Factory.define :pool do |pool|
  pool.name { Factory.next(:name) }
  pool.association :tenant
  pool.unlimited {false}
  pool.increase_rate 1
  pool.increase_type INCREASE_TYPE_ANNUAL_ANNIVERSARY
  pool.maximum_accrual_rate 10
  pool.accrual_day_number 1
  pool.increase_day_number 15
end
