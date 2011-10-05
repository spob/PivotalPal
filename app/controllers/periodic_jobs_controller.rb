class PeriodicJobsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :login_checks
#  before_filter :find_periodic_job, :only => [:show, :edit, :update, :destroy]
  respond_to :html, :xml

  def index
    @periodic_jobs = PeriodicJob.order("next_run_at DESC, last_run_at DESC").page(params[:page]).per(DEFAULT_ROWS_PER_PAGE)

    respond_with @periodic_jobs
  end

  def execute
    jobs_executed = PeriodicJob.run_jobs
    redirect_to periodic_jobs_path,
                :notice => (jobs_executed ? t('periodic_job.executed_pending_jobs') : t('periodic_job.no_executed_pending_jobs'))
  end

  # Clicking rerun on a job that has completed will cause they job to run one time
  def rerun
    job = PeriodicJob.find(params[:id])
    # todo: probably to verify that the job has infact run before allowing them to request that it be rerun
    RunOncePeriodicJob.create(
        :name => job.name,
        :job => job.job)
    flash[:notice] = t 'periodic_job.one_time_job_scheduled'
    redirect_to periodic_jobs_path
  end

  # Clicking rerun on a job that has completed will cause they job to run one time
  def run_now
    job = PeriodicJob.find(params[:id])
    job.update_attribute(:next_run_at, Time.now) if job.next_run_at.present?
    flash[:notice] = t 'periodic_job.run_now'
    redirect_to periodic_jobs_path
  end
end
