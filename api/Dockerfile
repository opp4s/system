FROM ruby:3.3-alpine

ENV BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH="/usr/local/bundle" \
    RAILS_ENV="production"

RUN apk add --no-cache \
  build-base \
  postgresql-dev \
  tzdata \
  git \
  curl \
  yaml-dev \
  libffi-dev \
  linux-headers

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install --jobs 4 --retry 3

COPY . .

# Garante diretórios de runtime que o Puma e o Rails precisam
RUN mkdir -p tmp/pids tmp/cache tmp/sockets log storage

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
