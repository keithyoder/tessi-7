# app/controllers/maps_controller.rb
# frozen_string_literal: true

class MapsController < ApplicationController
  skip_authorization_check

  def ponto
    @ponto = Ponto.find(params[:id])
    markers = params[:show_conexoes] ? build_conexoes_markers : []
    render partial: 'maps/viewer', locals: {
      latitude: @ponto.conexoes.georeferenciadas.first&.latitude || @ponto.latitude,
      longitude: @ponto.conexoes.georeferenciadas.first&.longitude || @ponto.longitude,
      zoom: params[:show_conexoes] ? 15 : 18,
      markers:
    }
  end

  private

  def build_conexoes_markers
    conexoes = @ponto.conexoes.georeferenciadas.includes(:pessoa).to_a
    status_map = Conexao.status_conexoes(conexoes)
    conexoes.map do |conexao|
      icon_data = determine_icon(conexao, status_map)
      {
        lat: conexao.latitude,
        lng: conexao.longitude,
        title: conexao.pessoa.nome,
        icon: icon_data[:icon],
        color: icon_data[:color],
        popup: conexao_popup_html(conexao, status_map[conexao.id])
      }
    end
  end

  def determine_icon(conexao, status_map)
    if conexao.bloqueado?
      { icon: 'bloqueado', color: '#ffc107' } # Yellow
    elsif status_map[conexao.id]
      { icon: 'conectado', color: '#28a745' } # Green
    else
      { icon: 'desconectado', color: '#dc3545' } # Red
    end
  end

  def ponto_popup_html(ponto)
    <<~HTML
      <strong>#{ponto.nome}</strong><br>
      Sistema: #{ponto.sistema}<br>
      Tecnologia: #{ponto.tecnologia}<br>
      Conexões: #{ponto.conexoes.count}<br>
      <a href="#{ponto_path(ponto)}" class="btn btn-sm btn-primary mt-2">Ver Detalhes</a>
    HTML
  end

  def conexao_popup_html(conexao, conectado)
    status_icon, status_text, status_color = if conexao.bloqueado?
                                               ['🟡', 'Bloqueado', '#ffc107']
                                             elsif conectado
                                               ['🟢', 'Conectado', '#28a745']
                                             else
                                               ['🔴', 'Desconectado', '#dc3545']
                                             end

    <<~HTML
      <strong>#{conexao.pessoa.nome}</strong><br>
      IP: #{conexao.ip}<br>
      MAC: #{conexao.mac}<br>
      <span style="color: #{status_color}">Status: #{status_icon} #{status_text}</span><br>
      <a href="#{conexao_path(conexao)}" class="btn btn-sm btn-primary mt-2">Ver Detalhes</a>
    HTML
  end
end
