# frozen_string_literal: true

class DumpsController < ApplicationController
  before_action :set_dump, only: [:show, :edit, :update, :destroy]

  # GET /dumps
  # GET /dumps.json
  def index
    @dumps = Dump.all
  end

  # GET /dumps/1
  # GET /dumps/1.json
  def show
    redirect_to @dump.file.expiring_url(10)
  end

  private

  def set_dump
    @dump = Dump.find(params[:id])
  end
end
