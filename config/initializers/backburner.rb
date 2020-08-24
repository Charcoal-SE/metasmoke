Backburner.configure do |config|
  config.beanstalk_url       = "beanstalk://127.0.0.1"
  config.tube_namespace      = "metasmoke.production"
  config.namespace_separator = "."
  config.on_error            = lambda { |e| puts e }
  # config.max_job_retries     = 3 # default 0 retries
  # config.retry_delay         = 2 # default 5 seconds
  # config.retry_delay_proc    = lambda { |min_retry_delay, num_retries| min_retry_delay + (num_retries ** 3) }
  config.default_priority    = 65536
  config.respond_timeout     = 600
  config.default_worker      = Backburner::Workers::Simple
  config.logger              = Logger.new(STDOUT)
  # config.priority_labels     = { :custom => 50, :useless => 1000 }
  # config.default_worker = Backburner::Workers::ThreadsOnFork
  config.reserve_timeout     = nil
  config.job_serializer_proc = lambda { |body| JSON.dump(body) }
  config.job_parser_proc     = lambda { |body| JSON.parse(body) }
end
