require 'rubygems'
require 'bundler/setup'

require 'json'

require 'dm-core'
require 'dm-migrations'
require 'govkit-ca'
require 'sinatra'

class Assignment
  include DataMapper::Resource

  property :id, Serial
  property :postal_code, String, index: true
  property :edid, Integer

  def self.find_electoral_districts_by_postal_code(postal_code, fresh = false)
    cache = fresh ? [] : all(postal_code: postal_code)
    if cache.empty?
      begin
        cache = GovKit::CA::PostalCode.find_electoral_districts_by_postal_code(postal_code).map do |edid|
          create(postal_code: postal_code, edid: edid)
        end
      rescue GovKit::CA::ResourceNotFound
        cache = [create(postal_code: postal_code)]
      end
    end
    cache.map(&:edid).compact
  end
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite://#{File.expand_path('../development.db', __FILE__)}")
DataMapper.finalize
DataMapper.auto_upgrade!

GovKit::CA::PostalCode::StrategySet.register(GovKit::CA::PostalCode::Strategy::ElectionsCa)
GovKit::CA::PostalCode::StrategySet.register(GovKit::CA::PostalCode::Strategy::LiberalCa)
GovKit::CA::PostalCode::StrategySet.register(GovKit::CA::PostalCode::Strategy::NDPCa)
GovKit::CA::PostalCode::StrategySet.register(GovKit::CA::PostalCode::Strategy::GreenPartyCa)

# 2015-08-28: Only riding name and not implemented.
# GovKit::CA::PostalCode::StrategySet.register(GovKit::CA::PostalCode::Strategy::ParlGcCa)
# 2015-08-28: Only riding name and not implemented.
# GovKit::CA::PostalCode::StrategySet.register(GovKit::CA::PostalCode::Strategy::ConservativeCa)
# 2015-08-28: Uses pre-2013 distribution.
# GovKit::CA::PostalCode::StrategySet.register(GovKit::CA::PostalCode::Strategy::CBCCa)
# 2015-08-28: Uses pre-2013 distribution.
# GovKit::CA::PostalCode::StrategySet.register(GovKit::CA::PostalCode::Strategy::DigitalCopyrightCa)

set :protection, except: [:json_csrf]

helpers do
  def find_electoral_districts_by_postal_code(postal_code)
    response.headers['Cache-Control'] = 'public, max-age=86400' # one day
    @postal_code = GovKit::CA::PostalCode.format_postal_code(postal_code)
    @electoral_districts = Assignment.find_electoral_districts_by_postal_code(@postal_code, params[:fresh])
  end
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

run Sinatra::Application

__END__
@@index
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>Free &amp; Open Source Postal Code to Electoral District Web Service</title>
  <style type="text/css">
    #container {
      width: 45em;
      margin: 0 auto;
      font-family: helvetica, sans-serif;
    }
    ul {
      list-style: none;
      padding-left: 0;
    }
    p {
      margin-bottom: 0;
    }
  </style>
</head>

<body>
  <div id="container">
    <h1>Postal Code to Electoral District API</h1>

    <h2>Deprecation Notice</h2>
    <p>You are strongly encouraged to use <a href="https://represent.opennorth.ca/">Represent</a> instead.</p>

    <h2>Examples</h2>
    <ul>
      <li>
        <p>A postal code containing a single electoral district:</p>
        <a href="/postal_codes/A1A1A1">https://postal-code-to-edid-webservice.herokuapp.com/postal_codes/A1A1A1</a>
      </li>
      <li>
        <p>A postal code containing multiple electoral districts:</p>
        <a href="/postal_codes/K0A1K0">https://postal-code-to-edid-webservice.herokuapp.com/postal_codes/K0A1K0</a>
      </li>
      <li>
        <p>You can also get the electoral districts in CSV format:</p>
        <a href="/postal_codes/K0A1K0/csv">https://postal-code-to-edid-webservice.herokuapp.com/postal_codes/K0A1K0/csv</a>
      </li>
      <li>
        <p>Or as JSONP for cross-domain AJAX requests:</p>
        <a href="/postal_codes/K0A1K0/jsonp?callback=success">https://postal-code-to-edid-webservice.herokuapp.com/postal_codes/K0A1K0/jsonp?callback=success</a>
      </li>
    </ul>

    <h2>Documentation</h2>
    <p>The API returns the IDs used by Elections Canada to represent electoral districts. For more documentation, <a href="https://github.com/opennorth-archive/postal_code_to_edid_webservice#readme">see here</a>.</p>
  </div>
</body>
</html>
