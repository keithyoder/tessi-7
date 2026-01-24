# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def destroy
      signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
      set_flash_message! :notice, :signed_out if signed_out

      respond_to do |format|
        format.html { redirect_to after_sign_out_path_for(resource_name), status: :see_other, allow_other_host: false }
      end
    end
  end
end
