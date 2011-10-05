class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)

    if user.role? :superuser
      can :manage, :all
    elsif user.role? :admin
      can :manage_org, [User, Category]
      can [:read, :update, :create], [User, Category], :tenant_id => user.tenant.id
    else
      can :update, User, :id => user.id
    end
  end
end
