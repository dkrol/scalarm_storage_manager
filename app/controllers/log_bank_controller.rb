class LogBankController < ApplicationController
  before_filter :authenticate, :except => [ :status ]

  def status
    render inline: "Hello world from Scalarm LogBank, it's #{Time.now} at the server!\n"
  end

  def get_simulation_output

  end

  def put_simulation_output

  end

  def delete_simulation_output

  end

  def get_experiment_output

  end

  def delete_experiment_output

  end

end
