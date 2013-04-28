require 'sinatra'
require 'koala'

#GET index.html.haml
get '/' do

	app_id = "535722936470267"
	app_secret = "90e6af31caa4301a6a22ef68e2da07b3"
	callback_url = "http://localhost:4567/"

	@oauth = Koala::Facebook::OAuth.new(app_id, app_secret, callback_url)
	@user_url = @oauth.url_for_oauth_code

	if ( params[:code] )

		begin
			@access_token = @oauth.get_access_token(params[:code])
		rescue Exception=>ex
			puts ex.message
		end

		if ( !!@access_token )

			@graph = Koala::Facebook::API.new(@access_token)

			begin
				@profile = @graph.get_object("me")
			rescue Exception=>ex
				puts ex.message
			end
		end
		
	end

	haml :index, :format => :html5

end

#GET listing.html.haml
get '/listing' do
	"Listing Page goes here"
end

#GET view.html.haml
get '/view/?:id?' do |id|
	"View page for id #{id}"
end

#GET edit.html.haml
get '/edit/?:id?' do |id|
	"Edit page for blog post with a ID of #{id}"
end

#Delete delete.html.haml
get '/delete/?:id?' do |id|
	"Delete with a id of #{id}"
end