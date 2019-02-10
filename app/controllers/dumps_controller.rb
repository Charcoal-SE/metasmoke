# frozen_string_literal: true

class DumpsController < ApplicationController
  before_action :set_dump, only: %i[show edit update destroy]

  # GET /dumps
  # GET /dumps.json
  def index
    @dumps = Dump.all

    presigner = Aws::S3::Presigner.new
    @redis_dumps = Aws::S3::Resource.new.bucket('erwaysoftware.redisdumps').objects.map do |o|
      { name: o.key, url: presigner.presigned_url(:get_object, bucket: 'erwaysoftware.redisdumps', key: o.key) }
    end
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
