class Card < ActiveRecord::Base
  belongs_to :card_request, :counter_cache => true
end
