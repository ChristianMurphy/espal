# The Ruby reference: a bare Rack app, the lightest thing Puma can serve.
require "json"

run lambda { |env|
  case env["PATH_INFO"]
  when "/plaintext"
    [200, { "content-type" => "text/plain", "server" => "Puma" }, ["Hello, World!"]]
  when "/json"
    [200, { "content-type" => "application/json", "server" => "Puma" }, [JSON.generate(message: "Hello, World!")]]
  else
    [404, {}, []]
  end
}
