# SSL

Prefer to do local development using SSL to resemble production as much as possible.

Phoenix has a generator for creating a self-signed certificate for HTTPS testing: `mix phx.gen.cert`.

However, when using Phoenix's generator you'll still have a "non secure" warning. To get rid of that warning, you can generate a certificate using [mkcert](https://github.com/FiloSottile/mkcert).

After you install `mkcert`, follow the steps below:

- Create a `cert` directory under `priv`: `mkdir priv/cert`.
- Generate a new certificate: `mkcert -key-file priv/cert/selfsigned_key.pem -cert-file priv/cert/selfsigned.pem localhost`.
- Run `mkcert -install` to install the certificate in the system trust store.
- You may also need to enable `Allow invalid certificates for resources loaded from localhost` on [Google Chrome flags](chrome://flags/#allow-insecure-localhost).
- Restart your local server: `mix phx.server`. You may also need to restart your browser.

Uneebee can also work as a multi-tenant app where multiple schools can use this app with their custom domain or our subdomain (i.e. `username.uneebee.test`). Therefore, it's useful to test those domains locally. You can do so by following the steps below:

## Setting up dnsmasq

`dnsmasq` allows you to resolve domains to your local machine without having to change your `/etc/hosts` file. To install `dnsmasq`:

```sh
brew install dnsmasq

# Create a configuration directory
mkdir -pv $(brew --prefix)/etc/

# Set up your domains
echo 'address=/uneebee.test/127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf
echo 'address=/.uneebee.test/127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf

# Start dnsmasq
sudo brew services start dnsmasq

# Add dnsmasq to your resolver
sudo mkdir -v /etc/resolver
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/uneebee.test'
```

_Note: After changing your `dnsmasq.conf` file, you'll need to restart `dnsmasq`_

## Generate a certificate for each domain

You can use `mkcert` to generate a certificate for each domain. In the example below, we're going to use the same domains as above:

```sh
mkcert -key-file priv/cert/selfsigned_key.pem -cert-file priv/cert/selfsigned.pem localhost uneebee.test "*.uneebee.test"
```

## Start your local server

That's it! You can now start your local server (`mix phx.server`) and test your domains using:

- https://uneebee.test:4001
- https://rug.uneebee.test:4001 (each school username can be used as a subdomain of uneebee.test)
- Or any other domain you added before.
