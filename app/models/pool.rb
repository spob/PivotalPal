class Pool < ActiveRecord::Base
  belongs_to :tenant, :counter_cache => true
  validates_uniqueness_of :name, :scope => :tenant_id
  validates_presence_of :name, :tenant_id
  validates_length_of :name, :maximum => 20, :allow_blank => true
  validates_presence_of :increase_type, :accrual_day_number,
                        :if => :is_limited?
  validates_presence_of :increase_day_number, :if => :increase_on_day_of_year?
  validates_presence_of :increase_rate, :maximum_accrual_rate, :if => :increases?
  validates_numericality_of :increase_rate, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_inclusion_of :increase_type,
                         :in => [INCREASE_TYPE_NONE, INCREASE_TYPE_ANNUAL_ANNIVERSARY, INCREASE_TYPE_ANNUAL_DAY_OF_YEAR],
                         :allow_nil => true
  validates_numericality_of :increase_day_number, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 365,
                            :only_integer => true, :allow_nil => true
  validates_numericality_of :maximum_accrual_rate, :greater_than_or_equal_to => 0.0, :allow_nil => true
  validates_numericality_of :accrual_day_number, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 31,
                            :only_integer => true, :allow_nil => true

  def annual_pto_increase user
    if !self.unlimited && user.hired_at
      case self.increase_type
        when INCREASE_TYPE_NONE
          0
        when INCREASE_TYPE_ANNUAL_ANNIVERSARY
          ensure_less_than_max_accrual_rate(self.increase_rate * user.years_tenure)
        when INCREASE_TYPE_ANNUAL_DAY_OF_YEAR
          puts "You passed a string"
        else
          nil
      end
    end
  end

  private

  def ensure_less_than_max_accrual_rate rate
    (rate > self.maximum_accrual_rate ? self.maximum_accrual_rate : rate)
  end

  def calculate_years_based_on_fixed_date user
    if user.hired_at
      one_year_anniversary = 1.year.since(user.hired_at)
      years = (Date.today.jd - one_year_anniversary.jd)/365
      years = years + 1 if one_year_anniversary.strftime("%j").to_i == self.accrual_day_number
      years
    end
  end

  def is_limited?
    !self.unlimited?
  end

  def increase_on_day_of_year?
    self.increase_type == INCREASE_TYPE_ANNUAL_DAY_OF_YEAR
  end

  def increases?
    self.increase_type && self.increase_type != INCREASE_TYPE_NONE
  end
end
