# frozen_string_literal: true

class Nf21ItensController < ApplicationController
  before_action :set_nf21_item, only: %i[show edit update destroy]

  # GET /nf21_itens
  # GET /nf21_itens.json
  def index
    @nf21_itens = Nf21Item.all
  end

  # GET /nf21_itens/1
  # GET /nf21_itens/1.json
  def show; end

  # GET /nf21_itens/new
  def new
    @nf21_item = Nf21Item.new
  end

  # GET /nf21_itens/1/edit
  def edit; end

  # POST /nf21_itens
  # POST /nf21_itens.json
  def create
    @nf21_item = Nf21Item.new(nf21_item_params)

    respond_to do |format|
      if @nf21_item.save
        format.html { redirect_to @nf21_item, notice: 'Nf21 item was successfully created.' }
        format.json { render :show, status: :created, location: @nf21_item }
      else
        format.html { render :new }
        format.json { render json: @nf21_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /nf21_itens/1
  # PATCH/PUT /nf21_itens/1.json
  def update
    respond_to do |format|
      if @nf21_item.update(nf21_item_params)
        format.html { redirect_to @nf21_item, notice: 'Nf21 item was successfully updated.' }
        format.json { render :show, status: :ok, location: @nf21_item }
      else
        format.html { render :edit }
        format.json { render json: @nf21_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /nf21_itens/1
  # DELETE /nf21_itens/1.json
  def destroy
    @nf21_item.destroy
    respond_to do |format|
      format.html { redirect_to nf21_itens_url, notice: 'Nf21 item was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_nf21_item
    @nf21_item = Nf21Item.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def nf21_item_params
    params.require(:nf21_item).permit(:nf_21, :item)
  end
end
