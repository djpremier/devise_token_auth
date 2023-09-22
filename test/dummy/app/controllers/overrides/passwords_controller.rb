# frozen_string_literal: true

module Overrides
  class PasswordsController < DeviseTokenAuth::PasswordsController
    OVERRIDE_PROOF = '(^^,)'.freeze

    # this is where users arrive after visiting the email confirmation link
    def edit
      @dta_resource = dta_resource_class.reset_password_by_token(
        reset_password_token: resource_params[:reset_password_token]
      )

      if @dta_resource && @dta_resource.id
        token = @dta_resource.create_token

        # ensure that user is confirmed
        @dta_resource.skip_confirmation! unless @dta_resource.confirmed_at

        @dta_resource.save!

        redirect_header_options = {
          override_proof: OVERRIDE_PROOF,
          reset_password: true
        }
        redirect_headers = build_redirect_headers(token.token,
                                                  token.client,
                                                  redirect_header_options)
        redirect_to(@dta_resource.build_auth_url(params[:redirect_url],
                                             redirect_headers),
                                             redirect_options)
      else
        raise ActionController::RoutingError, 'Not Found'
      end
    end
  end
end
