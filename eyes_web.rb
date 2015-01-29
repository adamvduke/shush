require 'sinatra/base'
require 'byebug' if ENV['RACK_ENV'] == 'development'

require_relative 'secrest_store'

TIMES = {
  "1 week" => 10080,
  "1 day" => 1440,
  "1 hour" => 60,
  "10 minutes" => 10,
  "1 minute" => 1,
}

class EyesWeb < Sinatra::Base
  def store
    @store ||= SecrestStore.new
  end

  def generate_key
    o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
    (0...50).map { o[rand(o.length)] }.join
  end

  get '/' do
    haml :input
  end

  post '/save' do
    key = generate_key
    store.save key, params[:secret]
    store.expire_in_minutes(key, params[:time]) if params[:expire] == 'time'

    # Generate url with key
    url = "http://localhost:9393/read/#{key}"
    haml :share, locals: { url: url, time: TIMES.key(params[:time].to_i) }
  end

  get "/read/:key" do
    key = params[:key]
    note = store.fetch key

    return 404 unless note

    if store.auto_expire?(key)
      ttl = store.expires_in(key)
    else
      store.destroy key
    end

    # Decrypt...

    haml :note, locals: { note: note, ttl: ttl }
  end

  not_found do
    'That note does not exist!'
  end

end
