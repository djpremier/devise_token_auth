# frozen_string_literal: true

module Overrides
  class RegistrationsController < DeviseTokenAuth::RegistrationsController
    OVERRIDE_PROOF = '(^^,)'.freeze

    def update
      if @dta_resource
        if @dta_resource.update(account_update_params)
          render json: {
            status: 'success',
            data:   @dta_resource.as_json,
            override_proof: OVERRIDE_PROOF
          }
        else
          render json: {
            status: 'error',
            errors: @dta_resource.errors
          }, status: 422
        end
      else
        render json: {
          status: 'error',
          errors: ['User not found.']
        }, status: 404
      end
    end
  end
end
