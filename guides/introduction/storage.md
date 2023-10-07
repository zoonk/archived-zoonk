# Storage

By default, we upload files to your local server and store them in the `priv/static/uploads` directory. However, we also support uploading files to [Cloudflare R2](https://www.cloudflare.com/developer-platform/r2/).

## Setting up Cloudflare R2

### CORS Policy

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
- `STORAGE_CDN_URL`: The URL of your CDN (i.e. `https://cdn.uneebee.com`).
- `STORAGE_CSP_CONNECT_SRC`: The CSP connect-src value to allow your server to connect to your bucket. For Cloudflare, you can use `https://*.r2.cloudflarestorage.com`.
