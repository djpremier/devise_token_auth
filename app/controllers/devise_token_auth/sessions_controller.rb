# frozen_string_literal: true

# see http://www.emilsoman.com/blog/2013/05/18/building-a-tested/
module DeviseTokenAuth
  class SessionsController < DeviseTokenAuth::ApplicationController
    before_action :set_user_by_token, only: [:destroy]
    after_action :reset_session, only: [:destroy]

    def new
      render_new_error
    end

    def create
      if field = (resource_params.keys.map(&:to_sym) & dta_resource_class.authentication_keys).first
        q_value = get_case_insensitive_field_from_resource_params(field)

        @dta_resource = find_resource(field, q_value)
      end

      if @dta_resource && valid_params?(field, q_value) && (!@dta_resource.respond_to?(:active_for_authentication?) || @dta_resource.active_for_authentication?)
        valid_password = @dta_resource.valid_password?(resource_params[:password])
        if (@dta_resource.respond_to?(:valid_for_authentication?) && !@dta_resource.valid_for_authentication? { valid_password }) || !valid_password
          return render_create_error_bad_credentials
        end

        create_and_assign_token

        sign_in(@dta_resource, scope: :user, store: false, bypass: false)

        yield @dta_resource if block_given?

        render_create_success
      elsif @dta_resource && !Devise.paranoid && !(!@dta_resource.respond_to?(:active_for_authentication?) || @dta_resource.active_for_authentication?)
        if @dta_resource.respond_to?(:locked_at) && @dta_resource.locked_at
          render_create_error_account_locked
        else
          render_create_error_not_confirmed
        end
      else
        hash_password_in_paranoid_mode
        render_create_error_bad_credentials
      end
    end

    def destroy
      # remove auth instance variables so that after_action does not run
      user = remove_instance_variable(:@dta_resource) if @dta_resource
      client = @token.client
      @token.clear!

      if user && client && user.tokens[client]
        user.tokens.delete(client)
        user.save!

        if DeviseTokenAuth.cookie_enabled
          # If a cookie is set with a domain specified then it must be deleted with that domain specified
          # See https://api.rubyonrails.org/classes/ActionDispatch/Cookies.html
          cookies.delete(DeviseTokenAuth.cookie_name, domain: DeviseTokenAuth.cookie_attributes[:domain])
        end

        yield user if block_given?

        render_destroy_success
      else
        render_destroy_error
      end
    end

    protected

    def valid_params?(key, val)
      resource_params[:password] && key && val
    end

    def get_auth_params
      auth_key = nil
      auth_val = nil
      # iterate thru allowed auth keys, use first found
      dta_resource_class.authentication_keys.each do |k|
        if resource_params[k]
          auth_val = resource_params[k]
          auth_key = k
          break
        end
      end

      # honor devise configuration for case_insensitive_keys
      if dta_resource_class.case_insensitive_keys.include?(auth_key)
        auth_val.downcase!
      end

      { key: auth_key, val: auth_val }
    end

    def render_new_error
      render_error(405, I18n.t('devise_token_auth.sessions.not_supported'))
    end

    def render_create_success
      render json: {
        data: resource_data(resource_json: @dta_resource.token_validation_response)
      }
    end

    def render_create_error_not_confirmed
      render_error(401, I18n.t('devise_token_auth.sessions.not_confirmed', email: @dta_resource.email))
    end

    def render_create_error_account_locked
      render_error(401, I18n.t('devise.mailer.unlock_instructions.account_lock_msg'))
    end

    def render_create_error_bad_credentials
      render_error(401, I18n.t('devise_token_auth.sessions.bad_credentials'))
    end

    def render_destroy_success
      render json: {
        success:true
      }, status: 200
    end

    def render_destroy_error
      render_error(404, I18n.t('devise_token_auth.sessions.user_not_found'))
    end

    private

    def resource_params
      params.permit(*params_for_resource(:sign_in))
    end

    def create_and_assign_token
      if @dta_resource.respond_to?(:with_lock)
        @dta_resource.with_lock do
          @token = @dta_resource.create_token
          @dta_resource.save!
        end
      else
        @token = @dta_resource.create_token
        @dta_resource.save!
      end
    end

    def hash_password_in_paranoid_mode
      # In order to avoid timing attacks in paranoid mode, we want the password hash to be
      # calculated even if no resource has been found. Devise's DatabaseAuthenticatable warden
      # strategy handles this case similarly:
      # https://github.com/heartcombo/devise/blob/main/lib/devise/strategies/database_authenticatable.rb
      dta_resource_class.new.password = resource_params[:password] if Devise.paranoid
    end
  end
end
