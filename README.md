# Pleroma Docker Image

Run Pleroma with a pre-bundled Debian image.

# Setup

## Install Docker

Go through Docker's instructions for installing on your machine. If you want to use a different
machine that has Docker, you can run `export DOCKER_HOST=ssh://user@host` to have your service run
remotely.

## Generate a Postgres password

Create a password (with openssl or however you like) for your database.

```shell
echo "POSTGRES_PASSWORD=$(openssl rand -base64 16)" >> .env
```

## Cloudflare Tunnel

> **Note**
> If you're more comfortable with Nginx, please open a pull request with instructions on setting
> that, so I can have instructions for that up as well as Cloudflare.

1. Sign up for Cloudflare and configure the DNS for your site with them.
2. Set up a free [Zero Trust service](https://dash.teams.cloudflare.com/).
3. Create a tunnel under `Access > Tunnels`. When you're asked to route traffic, set the public
   subdomain and hostname to anything you like and set the service to `http://pleroma`.

Put the `TUNNEL_TOKEN` in the `.env` file.

```shell
# in your .env file, make a line like this.
TUNNEL_TOKEN=YOUR_TOKEN_VALUE
```

## Configure Server

Generate the configuration files. Start by logging into the container. If you don't have the Docker
images, they'll be downloaded automatically for you.

```shell
docker compose run --rm --entrypoint /bin/bash pleroma
```

Once inside the image, generate the Pleroma's configuration. You'll want to use the same
domain/subdomain from the tunnel on this step.

```shell
/opt/pleroma/bin/pleroma_ctl instance gen \
  --output /mount/config/config.exs \
  --output-psql /mount/config/setup_db.psql \
  --dbhost postgres \
  --dbname pleroma \
  --dbuser postgres \
  --dbpass "$POSTGRES_PASSWORD" \
  --rum N \
  --uploads-dir /mount/uploads \
  --static-dir /mount/static \
  --listen-ip 0.0.0.0 \
  --listen-port 4000 \
  --read-uploads-description Y \
  --strip-uploads-location Y \
  --dedupe-uploads N \
  --anonymize-uploads Y
```

Still in the image, you'll want to generate the database.

```shell
psql -f /mount/config/setup_db.psql "postgres://postgres:$POSTGRES_PASSWORD@postgres:5432"
```

Finally, you'll want to run pending migrations. When you upgrade the base Pleroma image, you'll want
to re-run this command.

```shell
/opt/pleroma/bin/pleroma_ctl migrate
exit
```

Now you can run `docker compose up -d` to start the service and begin receiving traffic!
