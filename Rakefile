task :cron do
  if Time.now.wday == 0 # Sunday
    Rake::Task['db:backup'].invoke
  end
end

namespace :db do
  desc 'Backup the database to S3'
  task :backup do
    if ENV['AWS_ACCESS_KEY_ID'] and ENV['AWS_SECRET_ACCESS_KEY'] and ENV['AWS_BUCKET']
      require 'csv' # requires Ruby 1.9
      require 'yaml'
      require 'fog'
      require File.join(File.dirname(__FILE__), 'assignment')

      data = Assignment.all(:order => [:postal_code.asc, :edid.asc]).map do |assignment|
        [assignment.postal_code, assignment.edid]
      end

      filepath = "tmp/db-#{Time.now.strftime('%Y-%m-%d')}"

      CSV.open("#{filepath}.csv", 'w') do |csv|
        data.each do |row|
          csv << row
        end
      end

      File.open("#{filepath}.yml", 'w') do |f|
        YAML.dump(data, f)
      end

      %w(csv yml).each do |extension|
        `gzip #{filepath}.#{extension}`
        gz = "#{filepath}.#{extension}.gz"

        connection = Fog::Storage.new(
          :provider              => 'AWS',
          :aws_access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
          :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])

        directory = connection.directories.get ENV['AWS_BUCKET']

        directory.files.create(
          :key => "postal-code-to-edid-webservice/#{File.basename(gz)}",
          :body => File.open(gz),
          :public => true)
      end
    end
  end
end