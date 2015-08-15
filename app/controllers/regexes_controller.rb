class RegexesController < ApplicationController
  before_action :set_regex, only: [:show, :edit, :update, :destroy]

  # GET /regexes
  # GET /regexes.json
  def index
    @regexes = Regex.all
  end

  # GET /regexes/1
  # GET /regexes/1.json
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_regex
      @regex = Regex.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def regex_params
      params.require(:regex).permit(:reason)
    end
end
