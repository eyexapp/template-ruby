# ---- Builder stage ----
FROM ruby:3.2-slim AS builder

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential libpq-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle config set --local deployment true && \
    bundle install --jobs 4 --retry 3

COPY . .

# ---- Production stage ----
FROM ruby:3.2-slim

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends libpq5 && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd --system app && \
    useradd --system --gid app --create-home app

WORKDIR /app

COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle /usr/local/bundle

RUN chown -R app:app /app

USER app

ENV RACK_ENV=production \
    RUBY_YJIT_ENABLE=1 \
    PORT=3000

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ruby -e "require 'net/http'; Net::HTTP.get(URI('http://localhost:3000/health'))" || exit 1

CMD ["bundle", "exec", "puma", "-C", "-", "-b", "tcp://0.0.0.0:3000"]