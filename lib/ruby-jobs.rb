APP_ROOT ||= (Rails rescue nil).nil? ? Dir.pwd : Rails.root
APP_PATH ||= File.expand_path('config/application', APP_ROOT)

require_relative 'job_base/job.rb'

