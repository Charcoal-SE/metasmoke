# frozen_string_literal: true

class DumpsController < ApplicationController
  before_action :set_dump, only: %i[show edit update destroy]

  # GET /dumps
  # GET /dumps.json
  def index
    dump_list = YAML.load_file('/var/rails/metasmoke/shared/dumps/files.yml')
    @dumps = dump_list['database'].map { |k, v| { name: "#{k}.sql", url: v } }
    @redis_dumps = dump_list['redis'].map { |k, v| { name: "#{k}.rdb", url: v } }
  end
end
