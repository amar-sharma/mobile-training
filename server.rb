require 'bundler/setup'
require 'sinatra'
require './executer.rb'

helper = Handler.new

get '/start' do
  url = params[:url]
  id = params[:id]
  if !id || !url
    status 404
    'Parameter missing!'
  end
  result, msg = helper.start_browser(url,id)
  if !result
    status 403
    msg
  else
    msg
  end
end

get '/stop' do
  id = params[:id]
  if !id
    status 404
    'Device ID missing!'
  end
  result, msg = helper.stop_browser(id)
  if !result
    status 403
    msg
  else
    msg
  end
end
