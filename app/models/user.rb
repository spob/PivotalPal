class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :invitable, :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         :timeoutable, :lockable

  ROLES = [ROLE_SUPERUSER, ROLE_ADMIN]

  before_validation :strip_company_name
  before_update :create_logon, :create_tenant

  belongs_to :tenant, :counter_cache => true
  has_many :user_projects, :dependent => :destroy
  has_many :logons, :dependent => :destroy
  has_one :last_logon, :class_name => "Logon", :order => "id DESC"

  validates_uniqueness_of :email
  validates_length_of :first_name, :maximum => 25, :allow_blank => true
  validates_presence_of :last_name
  validates_length_of :last_name, :maximum => 25, :allow_blank => true
  validates_presence_of :company_name, :on => :create, :if => :need_tenant?
  validates_presence_of :time_zone
  validates_length_of :time_zone, :maximum => 50
  validates_length_of :company_name, :maximum => 50, :on => :create, :if => :need_tenant?, :allow_blank => true
  validates_format_of :company_name, :with => /^[\w\d]+$/,
                      :on => :create,
                      :if => :need_tenant?,
                      :allow_blank => true,
                      :message => I18n.t('user.bad_tenant_name')
  validate :validates_unique_tenant, :on => :create, :if => :need_tenant?

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :company_name,
                  :hired_at, :api_key

  scope :with_role, lambda { |role| {:conditions => "roles_mask & #{2**ROLES.index(role.to_s)} > 0 "} }
  scope :unconfirmed, where(:confirmed_at => nil)
  scope :confirmed, where{{confirmed_at.not_eq => nil}}

  def roles=(roles)
    self.roles_mask = (roles & ROLES).map { |r| 2**ROLES.index(r) }.sum
  end

  def roles
    ROLES.reject { |r| ((roles_mask || 0) & 2**ROLES.index(r)).zero? }
  end

  def role?(role)
    roles.include? role.to_s
  end

  def full_name
    [self.first_name, self.last_name].join(' ')
  end

  def role_symbols
    roles.map(&:to_sym)
  end

  def self.random_pronouncable_password(size = 4)
    c = %w(b c d f g h j k l m n p qu r s t v w x z ch cr fr nd ng nk nt ph pr rd sh sl sp st th tr)
    v = %w(a e i o u y)
    f, r = true, ''
    (size * 2).times do
      r << (f ? c[rand * c.size] : v[rand * v.size])
      f = !f
    end
    r
  end

  def years_tenure
    if self.hired_at
      years = (Date.today.jd - self.hired_at.jd)/365
      (years < 0 ? 0 : years)
    end
  end

  protected

  def need_tenant?
    self.tenant.nil?
  end

  private

  def create_tenant
    if self.confirmed_at && self.confirmed_at_changed? && tenant.nil?
      self.tenant = Tenant.create!(:name => self.company_name, :api_key => self.api_key)
      self.company_name = nil
      self.api_key = nil
      # set the user to be the admin for that org
      self.roles_mask = 2**ROLES.index(ROLE_ADMIN)
    end
  end

  def create_logon
    if self.current_sign_in_at_changed?
      self.logons.create!(:ip_address => self.current_sign_in_ip)
    end
  end

  def validates_unique_tenant
    if Tenant.find_by_name(self.company_name)
      # Ignore admin@timeout.com as this means it's a seeding operation
      errors.add(:company_name, I18n.t('user.tenant_taken')) unless email == "admin@timeout.com"
    end
  end

  def strip_company_name
    self.company_name = self.company_name.try(:strip)
    self.api_key = self.api_key.try(:strip)
  end
end
