require 'sinatra'
require 'govkit-ca'
require 'json'

require File.join(File.dirname(__FILE__), 'assignment')

def find_electoral_districts_by_postal_code(postal_code)
  response.headers['Cache-Control'] = 'public, max-age=86400' # one day
  @postal_code = GovKit::CA::PostalCode.format_postal_code(postal_code)
  @electoral_districts = Assignment.find_electoral_districts_by_postal_code(@postal_code)
end

get '/' do
  erb :index
end

get '/postal_codes/:postal_code' do
  begin
    content_type :json
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
  begin
    content_type :js
    find_electoral_districts_by_postal_code(params[:postal_code])
    callback = %w(callback jscallback jsonp jsoncallback).find{|x| params[x]}
    if @electoral_districts.empty?
      error 404, "#{callback}(#{{'error' => 'Postal code could not be resolved', 'link' => "http://www.elections.ca/scripts/pss/FindED.aspx?PC=#{@postal_code}&amp;image.x=0&amp;image.y=0"}.to_json})"
    else
      "#{callback}(#{@electoral_districts.to_json})"
    end
  rescue GovKit::CA::InvalidRequest
    error 400, "#{callback}(#{{'error' => 'Postal code invalid'}.to_json})"
  end
end

get '/postal_codes/:postal_code/csv' do
  begin
    content_type :csv
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
