QueryTracer.configure do |tracer|
  tracer.enabled = no
  tracer.colorize = true
  tracer.show_revision = true
  tracer.multiline = true
#  tracer.exclude_sql << %r{FROM sqlite_master}
end

QueryTracer::Logger.attach_to :active_record
