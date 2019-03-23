# Gosh this repo is so old!

FROM debian:jessie

ENV RUBY_VERSION 1.8.7-p374
ENV PATH /usr/local/rvm/gems/ruby-${RUBY_VERSION}/bin:/usr/local/rvm/gems/ruby-${RUBY_VERSION}@global/bin:/usr/local/rvm/rubies/ruby-${RUBY_VERSION}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/rvm/bin

RUN set -ex \
 && apt-get update && apt-get install -y curl \
 && gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
 && gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB \
 && curl -sSL https://get.rvm.io | bash -s stable --ruby=${RUBY_VERSION}

RUN \
  apt-get update && apt install -y libmysqlclient-dev libpq-dev

RUN \
  gem install bundler -v 1.10.6 && \
  gem update --system 1.8.25

ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock

RUN \
  bundle install

RUN \
 apt update && apt install -y nginx

ADD serving/nginx.conf /etc/nginx/sites-available/stonesoup

RUN \
  cd /etc/nginx/sites-enabled && ln -s ../sites-available/stonesoup stonesoup && \
  ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log
