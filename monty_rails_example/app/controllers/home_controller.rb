class HomeController < ApplicationController
  def index
    session[:pid] = $$

    text = [ ]
    text << "pid #{$$}"
    text << session[:id].inspect
    text << request.session.class.inspect
    text << MontyRailsExample::Application.instance.app.class.inspect

    $stderr.puts(text * "\n")

    @text = text
  end
end
