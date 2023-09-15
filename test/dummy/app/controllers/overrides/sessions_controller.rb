# frozen_string_literal: true

module Overrides
  class SessionsController < DeviseTokenAuth::SessionsController
    OVERRIDE_PROOF = '(^^,)'.freeze

    def create
      @dta_resource = resource_class.dta_find_by(email: resource_params[:email])

      if @dta_resource && valid_params?(:email, resource_params[:email]) && @dta_resource.valid_password?(resource_params[:password]) && @dta_resource.confirmed?
        @token = @dta_resource.create_token
        @dta_resource.save

        render json: {
          data: @dta_resource.as_json(except: %i[tokens created_at updated_at]),
          override_proof: OVERRIDE_PROOF
        }

      elsif @dta_resource && (not @dta_resource.confirmed?)
        render json: {
          success: false,
          errors: [
            "A confirmation email was sent to your account at #{@dta_resource.email}. "\
            'You must follow the instructions in the email before your account '\
            'can be activated'
          ]
        }, status: 401

      else
        render json: {
          errors: ['Invalid login credentials. Please try again.']
        }, status: 401
      end
    end
  end
end
