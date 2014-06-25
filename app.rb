require 'sinatra'
require 'govkit-ca'
require 'json'

require File.join(File.dirname(__FILE__), 'assignment')

def find_electoral_districts_by_postal_code(postal_code)
  response.headers['Cache-Control'] = 'public, max-age=86400' # one day
  @postal_code = GovKit::CA::PostalCode.format_postal_code(postal_code)
  @electoral_districts = Assignment.find_electoral_districts_by_postal_code(@postal_code, params[:fresh])
end

before do
  if request.request_method == 'OPTIONS'
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    halt 200
  end
end

get '/' do
  erb :index
end

get '/postal_codes/:postal_code' do
  content_type :json

  begin
    find_electoral_districts_by_postal_code(params[:postal_code])
    if @electoral_districts.empty?
      error 404, {'error' => 'Postal code could not be resolved', 'link' => "http://www.elections.ca/scripts/pss/FindED.aspx?PC=#{@postal_code}&amp;image.x=0&amp;image.y=0"}.to_json
    else
      @electoral_districts.map(&:to_s).to_json # call :to_s for backwards-compatibility
    end
  rescue GovKit::CA::InvalidRequest
    error 400, {'error' => 'Postal code invalid'}.to_json
  end
end

get '/postal_codes/:postal_code/jsonp' do
  content_type :js
  callback = params[%w(callback jscallback jsonp jsoncallback).find{|x| params[x]}]

  begin
    find_electoral_districts_by_postal_code(params[:postal_code])
    if @electoral_districts.empty?
      error 200, "#{callback}(#{{'error' => 'Postal code could not be resolved', 'link' => "http://www.elections.ca/scripts/pss/FindED.aspx?PC=#{@postal_code}&amp;image.x=0&amp;image.y=0"}.to_json})"
    else
      "#{callback}(#{@electoral_districts.to_json})"
    end
  rescue GovKit::CA::InvalidRequest
    error 200, "#{callback}(#{{'error' => 'Postal code invalid'}.to_json})"
  end
end

get '/postal_codes/:postal_code/csv' do
  content_type :csv

  begin
    find_electoral_districts_by_postal_code(params[:postal_code])
    if @electoral_districts.empty?
      error 404, "Postal code could not be resolved"
    else
      @electoral_districts.join(',')
    end
  rescue GovKit::CA::InvalidRequest
    error 400, "Postal code invalid"
  end
end
