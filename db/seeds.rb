if User.find_by_email("admin@timeout.com")
  puts "Admin user already exists...skipping"
else
  puts "Creating admin user..."
  admin_user = User.create!(:email => 'admin@timeout.com',
                            :password => "changeme",
                            :failed_attempts => 0,
                            :company_name => "TIMEOUT",
                            :last_name => "Admin")
  # And force it to be confirmed
  admin_user.confirmed_at = Time.now
  admin_user.confirmation_sent_at = Time.now
  admin_user.confirmation_token = nil
  admin_user.roles_mask = 1
  admin_user.save!
end

RunIntervalPeriodicJob.find_by_name_or_create :name => 'SessionCleaner', :job => 'SessionCleaner.clean', :interval => 3600 * 24 #once a day
RunIntervalPeriodicJob.find_by_name_or_create :name => 'SessionExpiry', :job => 'SessionCleaner.sweep', :interval => 1800 #once every 30 minutes
RunIntervalPeriodicJob.find_by_name_or_create :name => 'PeriodicJobCleanup', :job => 'PeriodicJob.cleanup', :interval => 3600  #once an hour
RunIntervalPeriodicJob.find_by_name_or_create :name => 'CardCleanup', :job => 'CardRequest.cleanup', :interval => 3600  #once an hour
RunIntervalPeriodicJob.find_by_name_or_create :name => 'SyncProjects', :job => 'Project.sync_projects', :interval => 600  #once every 10 minutes
