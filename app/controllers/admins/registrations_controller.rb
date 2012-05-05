class Admins::RegistrationsController < Devise::SessionsController
  prepend_before_filter :require_no_authentication, :only => [:new, :create, :cancel]
  prepend_before_filter :authenticate_scope!, :only => [:edit, :update, :destroy]
  include Devise::Controllers::InternalHelpers

  # GET /resource/sign_up
  def new
    resource = build_resource({})

    # Get info for captcha
    ayah = AYAH::Integration.new(captcha_publisher_key, captcha_scoring_key)

    @captcha_html = ayah.get_publisher_html
    respond_with_navigational(resource) { render_with_scope :new }
  end

  # POST /resource
  def create
    build_resource

    session_secret = params['session_secret'] # in this case, using Rails
    ayah = AYAH::Integration.new(captcha_publisher_key, captcha_scoring_key)
    @ayah_conversion_html = ayah.record_conversion(session_secret)
    ayah_passed = ayah.score_result(session_secret, request.remote_ip)

    if !ayah_passed && Rails.env.production?
      resource.errors[:base] << "Are you sure you are human?"
      clean_up_passwords(resource)
      respond_with_navigational(resource) { render_with_scope :new }
    elsif resource.save
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :inactive_signed_up, :reason => inactive_reason(resource) if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords(resource)
      respond_with_navigational(resource) { render_with_scope :new }
    end
  end

  # GET /resource/edit
  def edit
    render_with_scope :edit
  end

  # PUT /resource
  # We need to use a copy of the resource because we don't want to change
  # the current user in place.
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)

    if resource.update_with_password(params[resource_name])
      set_flash_message :notice, :updated if is_navigational_format?
      sign_in resource_name, resource, :bypass => true
      respond_with resource, :location => after_update_path_for(resource)
    else
      clean_up_passwords(resource)
      respond_with_navigational(resource) { render_with_scope :edit }
    end
  end

  # DELETE /resource
  def destroy
    resource.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message :notice, :destroyed if is_navigational_format?
    respond_with_navigational(resource) { redirect_to after_sign_out_path_for(resource_name) }
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  def cancel
    expire_session_data_after_sign_in!
    redirect_to new_registration_path(resource_name)
  end

  protected

  def captcha_publisher_key
    if Rails.env.production?
      "a40b79eadbff6c5e0884c908aafb1e20c9ef8486"
    else
      "b3df1e946e9d8503b0e0ab633f2b0e76490023ce"
    end
  end

  def captcha_scoring_key
    if Rails.env.production?
      "9d696f15ec84757f61f8836c4503bc5ba9bf3dae"
    else
      "50d6bbafa49a4ffb70dae5209a5477c6242b9976"
    end
  end

  # Build a devise resource passing in the session. Useful to move
  # temporary session data to the newly created user.
  def build_resource(hash=nil)
    hash ||= params[resource_name] || {}
    self.resource = resource_class.new_with_session(hash, session)
  end

  # The path used after sign up. You need to overwrite this method
  # in your own RegistrationsController.
  def after_sign_up_path_for(resource)
    after_sign_in_path_for(resource)
  end

  # Returns the inactive reason translated.
  def inactive_reason(resource)
    reason = resource.inactive_message.to_s
    I18n.t("devise.registrations.reasons.#{reason}", :default => reason)
  end

  # The path used after sign up for inactive accounts. You need to overwrite
  # this method in your own RegistrationsController.
  def after_inactive_sign_up_path_for(resource)
    root_path
  end

  # The default url to be used after updating a resource. You need to overwrite
  # this method in your own RegistrationsController.
  def after_update_path_for(resource)
    signed_in_root_path(resource)
  end

  # Authenticates the current scope and gets the current resource from the session.
  def authenticate_scope!
    send(:"authenticate_#{resource_name}!", :force => true)
    self.resource = send(:"current_#{resource_name}")
  end
end
