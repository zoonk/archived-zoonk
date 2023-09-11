# Installation

## Requirements

- You need `Elixir 1.15` or later and `Erlang 26` or later. Run `elixir -v` to find your current version for [Elixir](https://elixir-lang.org/install.html)
  and [Erlang](https://elixir-lang.org/install.html#installing-erlang).
- Install [Hex](https://hex.pm/): `mix local.hex`.
- Install `Phoenix`: `mix archive.install hex phx_new`.
- [PostgreSQL 15+](https://www.postgresql.org/).
- (Linux users only): [inotify-tools](https://github.com/inotify-tools/inotify-tools/wiki).

## Getting started

- Install dependencies and set up both the database and assets: `mix setup`.

## Local development

- Start a local server: `mix phx.server` (it will run on https://localhost:4001 or https://uneebee.test:4001 - see the SSL guide for more information).
- Run tests: `mix test`.
- Update translation files: `mix locale`.
