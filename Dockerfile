FROM ruby:2.7

######## FIXME: hardcoded password "password" everywhere

# The base image ruby:2.7 is Debian Bullseye

RUN apt-get update
# allow mariadb server to start, see comment in policy-rd.d
RUN sed -i~ 's/^exit 101/exit 0/' /usr/sbin/policy-rc.d
RUN apt-get install -y mariadb-server mariadb-client \
       nodejs yarnpkg libpcre3-dev

# Debian stupidly reserves yarn for a different package
# https://bugs.debian.org/940511
RUN ln -fs /usr/bin/yarnpkg /usr/local/bin/yarn

# Make sure IPv6 is disabled inside Docker to avoid
# https://github.com/puma/puma/issues/1062
RUN sysctl net.ipv6.conf.all.disable_ipv6
RUN sysctl net.ipv6.conf.default.disable_ipv6

RUN rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

RUN git clone https://github.com/antirez/redis redis-git
RUN cd redis-git \
    && make \
    && : '# you need tcl 8.5 or newer in order to run make test' \
    && make install

RUN git clone https://github.com/Charcoal-SE/redis-zhregex zhregex
RUN cd zhregex \
    && : '# workaround for https://github.com/Charcoal-SE/redis-zhregex/issues/1' \
    && sed -i~ '/^CC=clang/d' Makefile \
    && make CC=gcc

COPY . .

ENV RUBYOPT="-KU -E utf-8:utf-8"
ENV PATH="${PATH}:/redis-git/src/redis-cli:/redis-git/src/redis-server"
RUN gem install bundler
RUN bundle update --bundler
RUN bundle install
RUN ./createdb
RUN sed -i~ 's/^web:.*/& -b 0.0.0.0/' Procfile
RUN yarn install

# Don't gripe about connections from outside localhost
# https://stackoverflow.com/a/31273925
RUN sed -i~ '/^end/i\  config.web_console.whiny_requests = false' \
    config/environments/development.rb

EXPOSE 5000 8080
CMD ["./rundb"]

# Reminder to self:
# docker build -t metasmoke .  # --progress plain
# docker run --rm -it -p5000:5000 -p8080:8080 --name metasmoke metasmoke:latest
# docker tag metasmoke:latest tripleee/metasmoke:latest
# docker push tripleee/metasmoke:latest
