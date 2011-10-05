class Logon < ActiveRecord::Base
  belongs_to :user, :counter_cache => true

  validates_presence_of :ip_address

  scope :latest, order('logons.created_at DESC').limit(1)
end
