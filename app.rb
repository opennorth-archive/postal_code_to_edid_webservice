require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'govkit-ca'
require 'json'

# Currently caches postal code lookups forever. Should expire them on a schedule.
class Assignment
  include DataMapper::Resource
  property :id, Serial
  property :postal_code, String
  property :edid, Integer

  def self.find_electoral_districts_by_postal_code(postal_code)
    cache = all(:postal_code => postal_code)
    if cache.empty?
      cache = GovKit::CA::PostalCode.find_electoral_districts_by_postal_code(postal_code).map do |edid|
        create(:postal_code => postal_code, :edid => edid)
      end
    end
    cache.map(&:edid)
  end
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite://#{File.expand_path('../development.db', __FILE__)}")
DataMapper.finalize
DataMapper.auto_upgrade!

get '/' do
  erb :index
end

get '/postal_codes/:postal_code' do
  begin
    response.headers['Cache-Control'] = 'public, max-age=86400' # one day
    content_type :json
    postal_code = GovKit::CA::PostalCode.format_postal_code(params[:postal_code])
    # call :to_s to maintain backwards-compatibility with old service
    Assignment.find_electoral_districts_by_postal_code(postal_code).map(&:to_s).to_json
  rescue GovKit::CA::ResourceNotFound
    error 404, {'error' => 'Postal code could not be resolved', 'link' => "http://www.elections.ca/scripts/pss/FindED.aspx?PC=#{postal_code}&amp;image.x=0&amp;image.y=0"}.to_json
  rescue GovKit::CA::InvalidRequest
    error 400, {'error' => 'Postal code invalid'}.to_json
  end
end

get '/postal_codes/:postal_code/csv' do
  begin
    response.headers['Cache-Control'] = 'public, max-age=86400' # one day
    content_type :csv
    postal_code = GovKit::CA::PostalCode.format_postal_code(params[:postal_code])
    Assignment.find_electoral_districts_by_postal_code(postal_code).join(',')
  rescue GovKit::CA::ResourceNotFound
    error 404, "Postal code could not be resolved"
  rescue GovKit::CA::InvalidRequest
    error 400, "Postal code invalid"
  end
end
