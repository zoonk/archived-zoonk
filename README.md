<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/zoonk/.github/assets/4393133/5ed8820d-e54f-4e51-8d6d-9aee69ba7ac4">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/zoonk/.github/assets/4393133/16521c67-b891-4513-a83d-077b55e4c2db">
  <img alt="Zoonk Banner" src="https://github.com/zoonk/.github/assets/4393133/16521c67-b891-4513-a83d-077b55e4c2db">
</picture>

**WARNING:** This software is still in development and not ready for production. I'm making several changes to it. DO NOT USE IT IN PRODUCTION YET. The current version will break when v1.0 is released. I'll update this README when it's ready for production.

---

<p align="center">
  Open-source alternative to create interactive courses like Duolingo.
  <br />
  <a href="https://zoonk.org"><strong>Learn more »</strong></a>
  <br />
  <br />
  <a href="https://github.com/orgs/zoonk/projects">Roadmap</a>
  .
  <a href="https://github.com/orgs/zoonk/discussions">Community</a>
</p>

## About this project

Interactive learning is [more effective](https://www.sciencedaily.com/releases/2021/09/210930140710.htm) than traditional methods. [Learners remember](https://www.linkedin.com/pulse/how-does-interactive-learning-boost-outcomes/) 10% of what they hear, 20% of what they read but 80% of what they see and do. That's why 34 hours of Duolingo [are equivalent](https://support.duolingo.com/hc/en-us/articles/115000035183-Are-there-official-studies-about-Duolingo-) to a full university semester of language education.

We love Duolingo. We think those kind of interactive experiences should be used in more fields. That's why we're building Zoonk, an open-source platform to create interactive courses like Duolingo.

## Tech stack

- [Phoenix](https://www.phoenixframework.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- [Postgres](https://www.postgresql.org)
- [Tailwind CSS](https://tailwindcss.com/)
- [Resend](https://resend.com/)
- [Cloudflare Images](https://www.cloudflare.com/developer-platform/cloudflare-images)

We're deploying our cloud products to [Fly](https://fly.io/) and [Neon](https://neon.tech/).

## Getting started

Follow the instructions below to get Zoonk up and running on your local machine. We have a `Dockerfile` but that's used for deploying our demo app to [Fly](https://fly.io/). We don't have a Docker setup for local development yet. PRs are welcome!

### Requirements

- You need `Elixir 1.15` or later and `Erlang 26` or later. Run `elixir -v` to find your current version for [Elixir](https://elixir-lang.org/install.html)
  and [Erlang](https://elixir-lang.org/install.html#installing-erlang).
- Install [Hex](https://hex.pm/): `mix local.hex`.
- Install `Phoenix`: `mix archive.install hex phx_new`.
- [PostgreSQL 15+](https://www.postgresql.org/).
- (Linux users only): [inotify-tools](https://github.com/inotify-tools/inotify-tools/wiki).

### Local development

- Run `mix setup` to install both dependencies and set up both the database and assets.
- Run `mix seed` to fetch some initial data to the database ([See options](./priv/repo/seed/README.md)).
- Run `mix phx.server` to start a development server.
- Run `mix test` to run tests.
- Run `mix ci` to run our code quality checks.
- Run `mix locale` to update translation files.

## SSL on localhost

Prefer to do local development using SSL to resemble production as much as possible. You can use [mkcert](https://github.com/FiloSottile/mkcert) to generate a certificate. After you install `mkcert`, follow the steps below:

- Create a `cert` directory under `priv`: `mkdir priv/cert`.
- Generate a new certificate: `mkcert -key-file priv/cert/selfsigned_key.pem -cert-file priv/cert/selfsigned.pem localhost zoonk.test "*.zoonk.test" apple.test`.
- Run `mkcert -install` to install the certificate in the system trust store.
- You may also need to enable `Allow invalid certificates for resources loaded from localhost` on [Google Chrome flags](chrome://flags/#allow-insecure-localhost).
- Restart your local server: `mix phx.server`. You may also need to restart your browser.

  You also need to make sure your machine maps `localhost` to a test domain (we're using `zoonk.test` for this guide). `dnsmasq` allows you to resolve domains to your local machine without having to change your `/etc/hosts` file. To install `dnsmasq`:

```sh
brew install dnsmasq

# Create a configuration directory
mkdir -pv $(brew --prefix)/etc/

# Set up your domains
echo 'address=/zoonk.test/127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf
echo 'address=/.zoonk.test/127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf
echo 'address=/apple.test/127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf

# Add dnsmasq to your resolver
sudo mkdir -v /etc/resolver
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/zoonk.test'
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/apple.test'

# Start dnsmasq
sudo brew services start dnsmasq
```

That's it! You can now start your local server (`mix phx.server`) and test your domains using:

- https://zoonk.test:4001
- https://rug.zoonk.test:4001 (each school slug can be used as a subdomain of `zoonk.test`).
- Or any other domain you added before.

## Mailer

We're using [Resend](https://resend.com) to send emails. To make it work in production, you need to set the following environment variables on your server:

- `RESEND_API_KEY`: Your Resend API key.

## Storage

By default, we upload files to your local server and store them in the `priv/static/uploads` directory. However, we also support uploading files to [Cloudflare Images](https://www.cloudflare.com/developer-platform/cloudflare-images). To use Cloudflare Images, you'll need to set the following environment variables on your server:

- `CLOUDFLARE_ACCOUNT_ID`: Your Cloudflare account ID. You can find it on `Cloudflare Dashboard > Images > Overview`.
- `CLOUDFLARE_ACCOUNT_HASH`: Your Cloudflare account hash. You can find it on `Cloudflare Dashboard > Images > Overview`.
- `CLOUDFLARE_API_TOKEN`: Your Cloudflare API token. You can create a token on `Cloudflare Dashboard > My Profile > API Tokens`.

## Stripe

We use Stripe for processing payments. If you want to enable subscriptions, you need to set the following environment variables on your server:

- `STRIPE_API_KEY`: Your Stripe API key.
- `STRIPE_WEBHOOK_SECRET`: Your Stripe webhook secret.

Plus, you need to create a product for your subscription. We call this plan `flexible` and you can't customize plans at the moment. We fetch the price from the Stripe API, so make sure you add the `zoonk_flexible` [lookup key](https://stripe.com/docs/products-prices/manage-prices#lookup-keys) to your price.

Stripe can only be enabled for `saas` and `marketplace` apps. Make sure to choose one of those options when you first run this app.

## Sponsors

- [@adriy-be](https://github.com/adriy-be)
- Add your name or brand here by [sponsoring our project](https://github.com/sponsors/wceolin).
