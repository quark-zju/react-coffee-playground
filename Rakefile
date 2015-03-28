require 'sprockets/standalone'
require 'active_support/cache'

root_path = File.expand_path('../', __FILE__)

Sprockets::Standalone::RakeTask.new(:assets) do |task, sprockets|
  task.assets   = %w[application.js application.css *.png *.svg *.woff]
  task.sources  = %w[app/assets/javascripts app/assets/stylesheets vendor/assets/javascripts vendor/assets/stylesheets]
  task.output   = File.join(root_path, 'public/assets')
  task.digest   = false
  task.compress = true

  task.environment.cache = ActiveSupport::Cache::FileStore.new(File.join(root_path, 'tmp/cache/assets'))

  if ENV['COMPRESS']
    sprockets.js_compressor  = :uglifier
    sprockets.css_compressor = :sass
  end
end

slim_paths = Dir.chdir(root_path) { Dir['app/views/**/*.slim'].to_a }

html_paths = slim_paths.map do |slim_path|
  File.join('public', File.basename(slim_path).sub(/\.slim$/, '.html')).tap do |html_path|
    file html_path => slim_path  do |t|
      require 'slim'
      File.write(html_path, Slim::Template.new(t.prerequisites.first).render)
    end
  end
end

task :default => ['assets:compile'] + html_paths
