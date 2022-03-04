FROM ruby:2.6

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends openjdk-11-jre-headless raptor2-utils wait-for-it

# The Gemfile Caching Trick
# we install gems before copying the code in its own layer so that gems would not have to get
# installed every single time code is updated
RUN mkdir -p /srv/ontoportal/ncbo_cron
COPY Gemfile* /srv/ontoportal/ncbo_cron/
WORKDIR /srv/ontoportal/ncbo_cron
RUN gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)"
RUN bundle install
COPY . /srv/ontoportal/ncbo_cron
#CMD ["bundle","exec","rackup","-p","9393","--host","0.0.0.0"]
