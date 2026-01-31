# frozen_string_literal: true

Rails.application.config.session_store :cookie_store,
                                       key: '_tessi_telecom_session',
                                       secure: Rails.env.production?, # Only secure in production
                                       same_site: :lax,
                                       httponly: true
