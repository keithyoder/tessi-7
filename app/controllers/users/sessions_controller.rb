# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def new
      # Force write something to session
      session[:test] = 'hello'
      Rails.logger.info "Session test value: #{session[:test]}"
      Rails.logger.info "Session ID after write: #{session.id}"
      super
    end

    # DELETE /users/sign_out
    def destroy
      signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
      set_flash_message! :notice, :signed_out if signed_out

      respond_to do |format|
        format.html { redirect_to after_sign_out_path_for(resource_name), status: :see_other }
      end
    end
  end
end
