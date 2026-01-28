# frozen_string_literal: true

RSpec.shared_examples 'requer autenticação' do |method, action, params_proc = nil|
  it 'redireciona para login' do
    send(method, action, params: params_proc&.call || {})
    expect(response).to redirect_to(new_user_session_path)
  end
end

RSpec.shared_examples 'nega acesso sem permissão' do |method, action, params_proc = nil, user: nil|
  it 'redireciona para root' do
    sign_in(user || create(:user, :financeiro_n1))
    send(method, action, params: params_proc&.call || {})
    expect(response).to redirect_to(root_path)
  end
end

RSpec.shared_examples 'permite acesso com permissão' do |method, action, params_proc = nil, user: nil|
  it 'retorna sucesso' do
    sign_in(user) if user
    send(method, action, params: params_proc&.call || {})
    expect(response).to have_http_status(:ok)
  end
end
