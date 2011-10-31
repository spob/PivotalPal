class DevelopmentMailInterceptor
  def self.delivering_email(message)
    message.subject = "[#{message.to}] #{message.subject}"
    message.to = DEV_ALL_MAIL_ADDRESS
  end
end
