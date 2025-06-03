FROM ruby:3.2-alpine

WORKDIR /app
RUN apk add --no-cache curl build-base
COPY Gemfile .
RUN bundle install
COPY app.rb .

EXPOSE 4567

ENTRYPOINT ["ruby", "app.rb"]