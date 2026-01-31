# frozen_string_literal: true

Rails.application.config.session_store :cookie_store,
                                       key: '_tessi_telecom_session',
                                       domain: :all, # Changed from explicit domain
                                       secure: true,
                                       same_site: :lax,
                                       httponly: true,
                                       expire_after: 14.days
