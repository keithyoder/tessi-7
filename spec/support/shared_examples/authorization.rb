# spec/support/shared_examples/authorization.rb
# frozen_string_literal: true

RSpec.shared_examples 'action authorization' do |http_method, action, allowed_roles: [:admin], denied_roles: nil, params_block: nil, success_status: :ok| # rubocop:disable Metrics/ParameterLists
  let(:params) { params_block ? instance_exec(&params_block) : {} }

  # Calculate denied roles if not explicitly provided
  computed_denied_roles = denied_roles || (User.roles.keys.map(&:to_sym) - allowed_roles)

  context 'quando não autenticado' do
    it 'redireciona para login' do
      send(http_method, action, params: params)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  if allowed_roles.any?
    context 'com permissão' do
      allowed_roles.each do |role|
        context "para #{role}" do
          let(:user) { create(:user, role) }

          before { sign_in(user) }

          it 'permite acesso' do
            send(http_method, action, params: params)
            expect(response).to have_http_status(success_status)
          end
        end
      end
    end
  end

  if computed_denied_roles.any?
    context 'sem permissão' do
      computed_denied_roles.each do |role|
        context "para #{role}" do
          let(:user) { create(:user, role) }

          before { sign_in(user) }

          it 'nega acesso' do
            send(http_method, action, params: params)
            expect(response).to redirect_to(root_path)
          end
        end
      end
    end
  end
end
