class HomeController < ApplicationController
  def index
    session[:pid] = $$

    @text = text = [ ]
    text << "pid #{$$}"
    text << "request_id #{session[:request_id]}"
    text << "session_id #{request.session_options[:id].inspect}"
    #text << request.session.class.inspect
    #text << MontyRailsExample::Application.instance.app.class.inspect

    $stderr.puts("text ==========\n#{text * "\n"}\n=================")
    
    @times = 100
  end
end

