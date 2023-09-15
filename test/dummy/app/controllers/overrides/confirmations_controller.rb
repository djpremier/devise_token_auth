# frozen_string_literal: true

module Overrides
  class ConfirmationsController < DeviseTokenAuth::ConfirmationsController
    def show
      @dta_resource = resource_class.confirm_by_token(params[:confirmation_token])

      if @dta_resource && @dta_resource.id
        token = @dta_resource.create_token
        @dta_resource.save!

        redirect_header_options = {
          account_confirmation_success: true,
          config: params[:config],
          override_proof: '(^^,)'
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
