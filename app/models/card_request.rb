class CardRequest < ActiveRecord::Base
  belongs_to :user
  has_many :cards, :dependent => :destroy

  def self.cleanup
    CardRequest.where(:created_at.lt => 1.hours.ago ).order(:created_at).each do |cr|
      CardRequest.transaction do
        cr.destroy
      end
    end
  end
end
