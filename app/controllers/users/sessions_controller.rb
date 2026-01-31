# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    # Let Devise handle the create action naturally
    # The data: { turbo: false } in the form will ensure standard HTTP redirects work

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
