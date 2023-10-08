# Mailer

We're using [Amazon SES](https://aws.amazon.com/ses/) to send emails. To make it work, you need to set the following environment variables on your server:

- `MAILER_REGION`: AWS region.
- `MAILER_ACCESS_KEY`: Your access ID key.
- `MAILER_SECRET`: Your secret key.
