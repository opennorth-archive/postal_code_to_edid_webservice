require 'dm-core'
require 'dm-migrations'

class Assignment
  include DataMapper::Resource
  property :id, Serial
  property :postal_code, String, :index => true
  property :edid, Integer

  def self.find_electoral_districts_by_postal_code(postal_code, fresh = false)
    cache = fresh ? [] : all(:postal_code => postal_code)
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
