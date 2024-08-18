<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/zoonk/.github/assets/4393133/3a24c5e9-dc8e-4491-9aeb-95dd6f7283c8">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/zoonk/.github/assets/4393133/ddbb2208-feac-4a58-adac-f769cff4dc7f">
  <img alt="Zoonk Banner" src="https://github.com/zoonk/.github/assets/4393133/ddbb2208-feac-4a58-adac-f769cff4dc7f">
</picture>

> [!WARNING]
> We're temporarily pausing development on this repository. We're working on a new version of the platform. Those changes will be merged back to this repository when they're ready. You can expect this to happen by the summer of 2025. In the meantime, we do not recommend using this repository for new projects since the new changes won't be compatible with the current version.

---

<p align="center">
  Open-source alternative to create interactive courses like Duolingo.
  <br />
  <a href="https://zoonk.org"><strong>Learn more »</strong></a>
  <br />
  <br />
  <a href="https://github.com/zoonk/.github/blob/main/roadmap.md">Roadmap</a>
  ·
  <a href="https://github.com/orgs/zoonk/discussions">Community</a>
</p>

## Table of Contents

- [About this project](#about-this-project)
- [Tech stack](#tech-stack)
- [Getting started](#getting-started)
  - [Requirements](#requirements)
  - [Local development](#local-development)
- [SSL on localhost](#ssl-on-localhost)
- [Mailer](#mailer)
- [Storage](#storage)
- [Sponsors](#sponsors)

## About this project

Interactive learning is [more effective](https://www.sciencedaily.com/releases/2021/09/210930140710.htm) than traditional methods. [Learners remember](https://www.linkedin.com/pulse/how-does-interactive-learning-boost-outcomes/) 10% of what they hear, 20% of what they read but 80% of what they see and do. That's why 34 hours of Duolingo [are equivalent](https://support.duolingo.com/hc/en-us/articles/115000035183-Are-there-official-studies-about-Duolingo-) to a full university semester of language education.

We love Duolingo. We think those kinds of interactive experiences should be used in more fields. That's why we're building Zoonk, an open-source platform to create interactive courses like Duolingo.

## Tech stack

- **Backend**: [Phoenix](https://www.phoenixframework.org/)
- **Frontend**: [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- **Database**: [Postgres](https://www.postgresql.org) - [Neon](https://neon.tech/)
- **CSS**: [Tailwind CSS](https://tailwindcss.com/)
- **Email**: [Resend](https://resend.com/)
- **Storage**: [Tigris](https://tigrisdata.com/)
- **Hosting**: [Fly](https://fly.io/)

## Getting started

Follow the instructions below to get Zoonk up and running on your local machine. We have a `Dockerfile` for deploying our demo app to [Fly](https://fly.io/). For using Docker locally, [see this](./local/README.md).

### Requirements

- **Elixir 1.17+** and **Erlang 26+**. Run `elixir -v` to find your current version for [Elixir](https://elixir-lang.org/install.html) and [Erlang](https://elixir-lang.org/install.html#installing-erlang).
- **Hex**: `mix local.hex`.
- **Phoenix**: `mix archive.install hex phx_new`.
- **PostgreSQL 15+**: [PostgreSQL](https://www.postgresql.org/).
- (Linux users only): [inotify-tools](https://github.com/inotify-tools/inotify-tools/wiki).

### Local development

- Run `mix setup` to install dependencies and set up the database and assets.
- Run `mix seed` to fetch initial data to the database ([See options](./priv/repo/seed/README.md)).
- Run `mix phx.server` to start a development server.
- Run `mix test` to run tests or `mix test.watch` to run tests and watch for changes.
- Run `mix ci` to run code quality checks.
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
- https://apple.zoonk.test:4001 (each school slug can be used as a subdomain of `zoonk.test`).
- Or any other domain you added before.

## Mailer

We're using [Resend](https://resend.com) to send emails. To make it work in production, you need to set the following environment variables on your server:

- `RESEND_API_KEY`: Your Resend API key.

## Storage

You need to use an S3-compatible storage service to store your files. At Zoonk, we're using [Tigris](https://tigrisdata.com/). You need to add the following environment variables:

- `AWS_ACCESS_KEY_ID`: Your AWS access key ID.
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key.
- `AWS_REGION`: Your AWS region.
- `BUCKET_NAME`: Your AWS bucket name.
- `AWS_ENDPOINT_URL_S3`: Your AWS endpoint URL.
- `AWS_CDN_URL`: Your AWS CDN URL (optional. If missing, we'll use the S3 endpoint URL).
- `CSP_CONNECT_SRC`: Your S3 domain (i.e. `https://fly.storage.tigris.dev`).

## Translations

Follow the steps below to add a new language to Zoonk:

1. Copy the `priv/gettext/en` directory to `priv/gettext/<language_code>`.
2. Translate the `*.po` files.
3. Add the language code to the `locales` list in [config/config.exs](config/config.exs).
4. Add the language name to `@supported_locales` in [lib/translate/translate_plug.ex](lib/translate/translate_plug.ex).

## Sponsors

- [Gustavo A. Castillo](https://github.com/guscastilloa)
- [@adriy-be](https://github.com/adriy-be)
- Add your name or brand here by [sponsoring our project](https://github.com/sponsors/wceolin).
