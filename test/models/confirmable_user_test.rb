# frozen_string_literal: true

require 'test_helper'

class ConfirmableUserTest < ActiveSupport::TestCase
  describe ConfirmableUser do
    describe 'creation' do
      test 'email should be saved' do
        @dta_resource = create(:confirmable_user)
        assert @dta_resource.email.present?
      end
    end

    describe 'updating email' do
      test 'new email should be saved to unconfirmed_email' do
        @dta_resource = create(:confirmable_user, email: 'old_address@example.com')
        @dta_resource.update(email: 'new_address@example.com')
        assert @dta_resource.unconfirmed_email == 'new_address@example.com'
      end

      test 'old email should be kept in email' do
        @dta_resource = create(:confirmable_user, email: 'old_address@example.com')
        @dta_resource.update(email: 'new_address@example.com')
        assert @dta_resource.email == 'old_address@example.com'
      end

      test 'confirmation_token should be changed' do
        @dta_resource = create(:confirmable_user, email: 'old_address@example.com')
        old_token = @dta_resource.confirmation_token
        @dta_resource.update(email: 'new_address@example.com')
        assert @dta_resource.confirmation_token != old_token
      end
    end
  end
end
