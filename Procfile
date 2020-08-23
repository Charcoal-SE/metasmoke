web: bundle exec bin/rails s
webpacker: ./bin/webpack-dev-server
redis: ./redis-git/src/redis-server --port 6378 --loadmodule ./zhregex/module.so --dbfilename dump.rdb
beanstalkd: beanstalkd -l 127.0.0.1 -V
backburner: bundle exec rake backburner:work QUEUE=default,graphql_queries
