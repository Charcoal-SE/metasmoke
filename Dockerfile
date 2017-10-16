FROM ruby:2.3

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && printf 'deb http://dl.yarnpkg.com/debian/ stable main' \
       >/etc/apt/sources.list.d/yarn.list \
    && curl -sL https://deb.nodesource.com/setup_6.x | bash \
    && : '# ^ the above includes apt-get update' \
    && printf 'mysql-server mysql-server/%s password password\n' \
            root_password root_password_again \
       | debconf-set-selections \
    && : '# allow mysql server to start, see comment in policy-rd.d' \
    && sed -i 's/^exit 101/exit 0/' /usr/sbin/policy-rc.d \
    && : '# disable IPv6 to avoid https://github.com/puma/puma/issues/1062' \
    && : '# cannot use sed -i because I get Device or resource busy' \
    && cp /etc/hosts /tmp/hosts \
       && sed 's/^::1/#&/' /tmp/hosts >/etc/hosts \
      && nl -ba /etc/hosts \
    && apt-get install -y mysql-server mysql-client libmysqlclient-dev \
       nodejs yarn \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY . .
RUN bundle install \
    && ./createdb \
    && yarn install

######## TODO: minimize the number of RUN statements

EXPOSE 3000
CMD ["./rundb"]
