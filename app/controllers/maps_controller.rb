# app/controllers/maps_controller.rb
# frozen_string_literal: true

class MapsController < ApplicationController
  skip_authorization_check

  def ponto
    @ponto = Ponto.find(params[:id])

    # Build markers array
    markers = []
    # markers = [{
    #   lat: @ponto.latitude,
    #   lng: @ponto.longitude,
    #   title: @ponto.nome,
    #   icon: 'ponto',
    #   popup: ponto_popup_html(@ponto)
    # }]

    # Add conexões markers if requested
    if params[:show_conexoes]
      @ponto.conexoes.georeferenciadas.includes(:pessoa).find_each do |conexao|
        markers << {
          lat: conexao.latitude,
          lng: conexao.longitude,
          title: conexao.pessoa.nome,
          icon: conexao.bloqueado? ? 'bloqueado' : 'conexao',
          popup: conexao_popup_html(conexao)
        }
      end
    end

    render partial: 'maps/viewer', locals: {
      latitude: @ponto.conexoes.georeferenciadas.first.latitude,
      longitude: @ponto.conexoes.georeferenciadas.first.longitude,
      zoom: params[:show_conexoes] ? 15 : 18,
      markers: markers
    }
  end

  private

  def ponto_popup_html(ponto)
    <<~HTML
      <strong>#{ponto.nome}</strong><br>
      Sistema: #{ponto.sistema}<br>
      Tecnologia: #{ponto.tecnologia}<br>
      Conexões: #{ponto.conexoes.count}<br>
      <a href="#{ponto_path(ponto)}" class="btn btn-sm btn-primary mt-2">Ver Detalhes</a>
    HTML
  end

  def conexao_popup_html(conexao)
    <<~HTML
      <strong>#{conexao.pessoa.nome}</strong><br>
      IP: #{conexao.ip}<br>
      MAC: #{conexao.mac}<br>
      Status: #{conexao.bloqueado? ? '🔴 Bloqueado' : '🟢 Ativo'}<br>
      <a href="#{conexao_path(conexao)}" class="btn btn-sm btn-primary mt-2">Ver Detalhes</a>
    HTML
  end
end
