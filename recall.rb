require 'sinatra'
require 'data_mapper'
require 'rack-flash'
require 'sinatra/redirect_with_flash'

enable :sessions
use Rack::Flash, :sweep => true


DataMapper::setup(:default,"sqlite3://#{Dir.pwd}/recall.db")

# we’re setting up a new SQLite3 database in the current directory, named recall.db. Below that, we’re actually setting up a ‘Notes’ table in the database.

class Note #While we’re calling the class ‘Note’, DataMapper will create the table as ‘Notes’. This is in keeping with a convention which Ruby on Rails and other frameworks and ORM modules follow.
 include DataMapper::Resource
  property :id, Serial
  property :content, Text, :required => true
  property :complete, Boolean, :required => true, :default => false
  property :created_at, DateTime
  property :updated_at, DateTime
end

DataMapper.finalize.auto_upgrade!


		helpers do
			include Rack::Utils
			alias_method :h, :escape_html
		end

# Inside the class, we’re setting up the database schema. The ‘Notes’ table will have 5 fields. An id field which will be an integer primary key and auto-incrementing (this is what ‘Serial’ means). A content field containing text, a boolean complete field and two datetime fields, created_at and updated_at.
# The very last line instructs DataMapper to automatically update the database to contain the tables and fields we have set, and to do so again if we make any changes to the schema.


get '/' do
  @notes = Note.all :order => :id.desc
  @title = 'All Notes'
  if @notes.empty?
    flash[:error] = 'No notes found. Add your first below.'
  end

  erb :home
end

post '/' do
  n = Note.new
  n.content = params[:content]
  n.created_at = Time.now
  n.updated_at = Time.now
  n.save
  redirect '/'
end


# Make sure you add this route somewhere above the get '/:id' route, otherwise a request for rss.xml would be mistaken for a post ID!

get '/rss.xml' do
	@notes = Note.all :order => :id.desc
	builder :rss
end





get '/:id' do
  @note = Note.get params[:id]
  @title = "Edit note ##{params[:id]}"
  erb :edit
end
# But GET and POST aren’t the only “HTTP verbs” – there’s two more you should know about: PUT and DELETE.
# Technically, POST should only be used for creating something – like creating a new Note in your awesome new web app, for example.
# PUT is the verb for modifying something. And DELETE, you guessed it, is for deleting something.

put '/:id' do
  n = Note.get params[:id]
  n.content = params[:content]
  n.complete = params[:complete] ? 1 : 0
  n.updated_at = Time.now
  n.save
  redirect '/'
end

get '/:id/delete' do
  @note = Note.get params[:id]
  @title = "Confirm deletion of note ##{params[:id]}"
  erb :delete
end


delete '/:id' do
  n = Note.get params[:id]
  n.destroy
  redirect '/'
end

get '/:id/complete' do
  n = Note.get params[:id]
  n.complete = n.complete ? 0 : 1 # flip it
  n.updated_at = Time.now
  n.save
  redirect '/'
end

	

