FROM ruby:2.4

RUN git clone https://github.com/eric/solar_power.git

WORKDIR /solar_power

RUN bundle install

ENTRYPOINT ["bundle", "exec", "bin/solar_power"]
