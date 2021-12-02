namespace :grape do
  desc 'Print grape API routes'
  task routes: :environment do
    API::Base.routes.each do |route|
      puts "#{route.options[:method]} #{route.path}"
    end
  end
end