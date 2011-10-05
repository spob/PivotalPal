class GeneralMailer < ActionMailer::Base

  def failed_periodic_job job
    @job = job
    mail(:to => User.with_role('superuser').collect(&:email), :subject => "Failed Periodic Job", :from => "bob@sturim.org")
  end
end
