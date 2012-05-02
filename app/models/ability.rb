class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here.
    user ||= User.new # guest user (not logged in)

    if user.role? :superuser
      can :manage, :all
      can :split, Story
    elsif user.role? :admin
      can [:read, :update, :create, :destroy], [User, Project], :tenant_id => user.tenant.id
      can [:refresh, :renumber], Project, :tenant_id => user.tenant.id
      can :split, Story, :iteration => {:project => {:tenant_id => user.tenant.try(:id)}}
      can :update, Tenant, :id => user.tenant.id
    end
    can [:read, :storyboard, :burndown, :stats, :select_to_print, :print], Project, :tenant_id => user.tenant.try(:id)
    can :read, Story, :iteration => {:project => {:tenant_id => user.tenant.try(:id)}}
    can :read, [CardRequest, Card], :user_id => user.try(:id)
    can :update, User, :id => user.id
  end
end
