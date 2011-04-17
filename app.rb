require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'govkit-ca'
require 'json'

# Currently caches postal code lookups forever. Should expire them on a schedule.
class Assignment
  include DataMapper::Resource
  property :id, Serial
  property :postal_code, String, :index => true
  property :edid, Integer

  def self.find_electoral_districts_by_postal_code(postal_code)
    cache = all(:postal_code => postal_code)
    if cache.empty?
      begin
        cache = GovKit::CA::PostalCode.find_electoral_districts_by_postal_code(postal_code).map do |edid|
          create(:postal_code => postal_code, :edid => edid)
        end
      rescue GovKit::CA::ResourceNotFound
        cache = [create(:postal_code => postal_code)]
      end
    end
    cache.map(&:edid).compact
  end
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite://#{File.expand_path('../development.db', __FILE__)}")
DataMapper.finalize
DataMapper.auto_upgrade!

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
