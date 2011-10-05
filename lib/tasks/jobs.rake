namespace :jobs do
  task :run => :environment do
    puts "Executing periodic jobs"
    PeriodicJob.run_jobs
  end
end
