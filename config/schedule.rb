# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#

set :output, "/home/bob/dev/pivotalpal/log/cron_log.log"
set :environment, "development"
#

every 1.minute do
   rake "jobs:run"
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
end

#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
