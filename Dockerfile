FROM ruby:2.5

######## FIXME: hardcoded password "password" everywhere

# The base image ruby:2.3 is Debian Jessie
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg \
       | gpg --dearmor > /etc/apt/trusted.gpg.d/yarn.gpg \
    && printf 'deb http://dl.yarnpkg.com/debian/ stable main\n' \
       >/etc/apt/sources.list.d/yarn.list \
    && curl -sL https://deb.nodesource.com/setup_6.x | bash \
    && : '# ^ the above includes apt-get update' \
    && printf 'mysql-server mysql-server/%s password password\n' \
            root_password root_password_again \
       | debconf-set-selections \
    && : '# allow mysql server to start, see comment in policy-rd.d' \
    && sed -i~ 's/^exit 101/exit 0/' /usr/sbin/policy-rc.d \
    && apt-get install -y mysql-server mysql-client default-libmysqlclient-dev \
       nodejs yarn libpcre3-dev \
       \
    && git clone https://github.com/antirez/redis redis-git \
    && cd redis-git \
    && make \
    && : '# you need tcl 8.5 of newer in order to run make test' \
    && make install \
    && cd .. \
    \
    && git clone https://github.com/Charcoal-SE/redis-zhregex zhregex \
    && cd zhregex \
    && : '# workaround for https://github.com/Charcoal-SE/redis-zhregex/issues/1' \
    && sed -i~ '/^CC=clang/d' Makefile \
    && make CC=gcc \
    \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY . .
ENV RUBYOPT="-KU -E utf-8:utf-8"
ENV PATH="${PATH}:/redis-git/src/redis-cli:/redis-git/src/redis-server"
RUN gem install bundler \
    && bundle install \
    && ./createdb \
    && sed -i~ 's/^web:.*/& -b 0.0.0.0/' Procfile \
    && yarn install

######## TODO: minimize the number of RUN statements

EXPOSE 5000 8080
CMD ["./rundb"]
