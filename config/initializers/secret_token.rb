# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

puts "Move secret_toket to environment, or at least modify in production"
Stonesoup::Application.config.secret_token = 'ed6b263396f1ec70c971743e06c297e6b3ecace4a923f3d672be9137753aad60f34986c1940c2021b364d91d2cd4bb975ba0a92135480329fe5035c2d42aba27'
