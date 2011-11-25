if Rails.env.development?

  QueryTracer.configure do |tracer|
    tracer.enabled = false
    tracer.colorize = true
    tracer.show_revision = true
    tracer.multiline = true
#  tracer.exclude_sql << %r{FROM sqlite_master}
  end

  QueryTracer::Logger.attach_to :active_record
end
