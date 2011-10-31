class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)

    if user.role? :superuser
      can :manage, :all
    elsif user.role? :admin
#      can :manage_org, [User, Project]
      can [:read, :update, :create, :destroy], [User, Project], :tenant_id => user.tenant.id
      can :refresh_project, Project, :tenant_id => user.tenant.id
      can :update, Tenant, :id => user.tenant.id
    else
      can :read, Project, :tenant_id => user.tenant.try(:id)
      can :read, Story, :iteration => { :project => { :tenant_id => user.tenant.try(:id) } }
    end
    can :read, [CardRequest, Card], :user_id => user.try(:id)
    can :update, User, :id => user.id
  end
end
