require 'sinatra'
require 'sinatra/cookies'

require 'koala'
require 'data_mapper'

enable :sessions

#Setup the MYSQL database connection
DataMapper.setup( :default, 'mysql://root:root@127.0.0.1:8889/sinatra' )

def render_file(filename)
  contents = File.read(filename)
  Haml::Engine.new(contents).render
end

#GET index.html.haml
get '/' do

	#Set the logged in cookie to NULL so we don get weird behaviour in the view
	session[:logged_in] = false

	app_id = "535722936470267"
	app_secret = "90e6af31caa4301a6a22ef68e2da07b3"
	callback_url = "http://localhost:4567/"

	@oauth = Koala::Facebook::OAuth.new(app_id, app_secret, callback_url)
	@user_url = @oauth.url_for_oauth_code(:permissions => 'publish_actions')

	if ( params[:code] )
		
		begin
			@access_token = @oauth.get_access_token(params[:code])
		rescue Exception=>ex
			puts ex.message
		end

		if ( !!@access_token )

			@graph = Koala::Facebook::API.new(@access_token)
			session[:access_token] = @access_token
			session[:graph] = @graph

			begin
				@profile = @graph.get_object("me")

				#If the users profile has been retrieved successfully we can save their facebook ID into the database for future reference
				if ( !!@profile )

					@profile_id = @profile['id']

					#Check if the users facebook id is already in the database
					#If it is start the session
					#If it isnt add it to the database and start the session
					@profile_name = @profile['name']
					@profile_location = @profile['hometown']['name']

					@user_save = User.first_or_create(
									:name => @profile_name,
									:facebook_id => @profile_id,
									:location => @profile_location
								)

					session[:id] = @user_save[:id]
					session[:logged_in] = true
				end

			rescue Exception=>ex
				puts ex.message
			end
		end
	end

	haml :index, :format => :html5

end

#POST message.html.haml
post '/' do

	if params[:message]
		if ( session[:graph] )

			begin
				session[:graph].put_wall_post( "This is a test message: #{params[:message]}" )
			rescue Exception=>ex
				puts ex.message
			end
		end
	end

	haml :message, :format => :html5

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

#Set up some models / migrations
class User
	include DataMapper::Resource

	property :id, Serial
	property :name, String
	property :facebook_id, String
	property :location, String
	property :create_date, DateTime

end

DataMapper.auto_upgrade!

