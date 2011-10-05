
Factory.define :logon do |logon|
  logon.ip_address { "1.2.3.4" }
  logon.association :user
end
