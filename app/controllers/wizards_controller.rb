class WizardsController < ApplicationController

  swagger_controller :wizards, "Wizards"

  swagger_api :index do
    summary "Fetches all the wizards."
    response :ok, "Success"
  end

  def index
    @wizards = Wizard.all
    render json: @wizards.to_json.html_safe
  end
end