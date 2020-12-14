import Config

config :samhstn,
  port: System.fetch_env!("SAMHSTN_PORT"),
  host: System.fetch_env!("SAMHSTN_HOST"),
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  assets_bucket: System.fetch_env!("SAMHSTN_ASSETS_BUCKET")
