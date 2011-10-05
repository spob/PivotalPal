module LoginChecker

  def login_checks
    if user_signed_in?
      raise ForcePasswordException, t('password.must_change_password'), caller if current_user.temporary_password
    end
  end
end
