FROM ruby:3.2-alpine

RUN apk add --no-cache curl build-base
COPY Gemfile .
RUN bundle install
COPY app.rb .

ENTRYPOINT ["ruby", "app.rb"]