<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/zoonk/uneebee/assets/4393133/35b230e5-97cb-4de1-997b-92b2c9201f01">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/zoonk/uneebee/assets/4393133/cd481f3b-0700-47b6-a529-19d9226689d5">
  <img alt="UneeBee Banner" src="https://github.com/zoonk/uneebee/assets/4393133/cd481f3b-0700-47b6-a529-19d9226689d5">
</picture>

<p align="center">
  Open-source alternative to create interactive courses like Duolingo.
  <br />
  <a href="https://uneebee.com"><strong>Learn more »</strong></a>
  <br />
  <br />
  <a href="https://zoonk.org">Cloud</a>
  .
  <a href="https://github.com/orgs/zoonk/projects/11">Roadmap</a>
  .
  <a href="https://github.com/orgs/zoonk/discussions">Community</a>
</p>

## About this project

Interactive learning is [more effective](https://www.sciencedaily.com/releases/2021/09/210930140710.htm) than traditional methods. [Learners remember](https://www.linkedin.com/pulse/how-does-interactive-learning-boost-outcomes/) 10% of what they hear, 20% of what they read but 80% of what they see and do. That's why 34 hours of Duolingo [are equivalent](https://support.duolingo.com/hc/en-us/articles/115000035183-Are-there-official-studies-about-Duolingo-) to a full university semester of language education.

We love Duolingo. We think those kind of interactive experiences should be used in more fields. That's why we're building UneeBee, an open-source platform to create interactive courses like Duolingo. You can use it at your [organization](https://wikaro.com), [school](https://educasso.com), or using [our marketplace](https://mywisek.com) to share your experience in a fun way.

## Tech stack

- [Phoenix](https://www.phoenixframework.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- [Postgres](https://www.postgresql.org)
- [Tailwind CSS](https://tailwindcss.com/)
- [Resend](https://resend.com/)
- [Cloudflare R2](https://www.cloudflare.com/developer-platform/r2/)

We're deploying our cloud products to [Fly](https://fly.io/) and [Neon](https://neon.tech/).

## Getting started

Follow the instructions below to get UneeBee up and running on your local machine. We have a `Dockerfile` but that's used for deploying our demo app to [Fly](https://fly.io/). We don't have a Docker setup for local development yet. PRs are welcome!

### Requirements

- You need `Elixir 1.15` or later and `Erlang 26` or later. Run `elixir -v` to find your current version for [Elixir](https://elixir-lang.org/install.html)
  and [Erlang](https://elixir-lang.org/install.html#installing-erlang).
- Install [Hex](https://hex.pm/): `mix local.hex`.
- Install `Phoenix`: `mix archive.install hex phx_new`.
- [PostgreSQL 15+](https://www.postgresql.org/).
- (Linux users only): [inotify-tools](https://github.com/inotify-tools/inotify-tools/wiki).

### Local development

- Run `mix setup` to install both dependencies and set up both the database and assets.
- Run `mix seed` to fetch some initial data to the database.
- Run `mix phx.server` to start a development server.
- Run `mix test` to run tests.
- Run `mix ci` to run our code quality checks.
- Run `mix locale` to update translation files.

## SSL on localhost

Prefer to do local development using SSL to resemble production as much as possible. You can use [mkcert](https://github.com/FiloSottile/mkcert) to generate a certificate. After you install `mkcert`, follow the steps below:

- Create a `cert` directory under `priv`: `mkdir priv/cert`.
- Generate a new certificate: `mkcert -key-file priv/cert/selfsigned_key.pem -cert-file priv/cert/selfsigned.pem localhost uneebee.test "*.uneebee.test"`.
- Run `mkcert -install` to install the certificate in the system trust store.
- You may also need to enable `Allow invalid certificates for resources loaded from localhost` on [Google Chrome flags](chrome://flags/#allow-insecure-localhost).
- Restart your local server: `mix phx.server`. You may also need to restart your browser.

  You also need to make sure your machine maps `localhost` to a test domain (we're using `uneebee.test` for this guide). `dnsmasq` allows you to resolve domains to your local machine without having to change your `/etc/hosts` file. To install `dnsmasq`:

```sh
brew install dnsmasq

# Create a configuration directory
mkdir -pv $(brew --prefix)/etc/

# Set up your domains
echo 'address=/uneebee.test/127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf
echo 'address=/.uneebee.test/127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf

# Add dnsmasq to your resolver
sudo mkdir -v /etc/resolver
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/uneebee.test'

# Start dnsmasq
sudo brew services start dnsmasq
```

That's it! You can now start your local server (`mix phx.server`) and test your domains using:

- https://uneebee.test:4001
- https://rug.uneebee.test:4001 (each school slug can be used as a subdomain of `uneebee.test`).
- Or any other domain you added before.

## Mailer

We're using [Resend](https://resend.com) to send emails. To make it work in production, you need to set the following environment variables on your server:

- `RESEND_API_KEY`: Your Resend API key.

## Storage

By default, we upload files to your local server and store them in the `priv/static/uploads` directory. However, we also support uploading files to [Cloudflare R2](https://www.cloudflare.com/developer-platform/r2/). To use R2, you'll need to add a new CORS policy:

Go to `Settings` -> `CORS Policy` to add a new CORS policy. You can use the following settings:

```
[
  {
    "AllowedOrigins": [
      "http://localhost:4000",
      "https://localhost:4001",
      "https://uneebee.test:4001"
    ],
    "AllowedMethods": [
      "GET",
      "PUT",
      "POST"
    ],
    "AllowedHeaders": [
      "*"
    ],
    "ExposeHeaders": []
  }
]
```

Make sure to add/update the `AllowedOrigins` list with the domains you want to allow to upload files to your server.

### Reading images

You need to enable public access to allow your users to read images. Go to `Settings` -> `Public Access` -> `Custom Domains` to do it. You must add a domain where you'll access your images. For example, we use `cdn.uneebee.com` for our production server.

### Setting up environment variables

You need to set the following environment variables on your server:

- `STORAGE_BUCKET`: The name of your bucket.
- `STORAGE_ACCESS_ID`: Your access ID key.
- `STORAGE_ACCESS_KEY`: Your access key.
- `STORAGE_BUCKET_URL`: The URL of your bucket. (i.e. `https://mybucketurl.r2.cloudflarestorage.com`).

## Sponsors

We don't have any sponsors yet. Add your brand here by [sponsoring our project](https://github.com/sponsors/wceolin).

- [See all sponsors and supporters](https://zoonk.org/en/sponsors)
