# The Rails reference: an API-only app in one file, with the default middleware for API mode.
require "rails"
require "action_controller/railtie"

class BenchApp < Rails::Application
  config.load_defaults 8.1
  config.api_only = true
  config.eager_load = true
  config.secret_key_base = "bench"
  config.hosts.clear
  config.logger = Logger.new($stdout, level: Logger::WARN)
  config.log_level = :warn
end

class HelloController < ActionController::API
  def plaintext
    render plain: "Hello, World!"
  end

  def json
    render json: { message: "Hello, World!" }
  end
end

BenchApp.initialize!
BenchApp.routes.draw do
  get "/plaintext", to: "hello#plaintext"
  get "/json", to: "hello#json"
end

run BenchApp
