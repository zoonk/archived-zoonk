# Use the official Elixir image as the base image
FROM elixir:latest

# Install Hex and Phoenix
RUN mix local.hex --force && \
    mix archive.install hex phx_new --force

# Install PostgreSQL client
RUN apt-get update && \
    apt-get install -y postgresql-client

# Set the working directory
WORKDIR /app

# Copy the application files to the container
COPY . /app

# Expose Phoenix server port
EXPOSE 4000
