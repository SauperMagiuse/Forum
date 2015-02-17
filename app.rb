require 'sinatra'
require 'sequel'

enable 'sessions'

#Open Database
DB = Sequel.connect('sqlite://db/userdata.db') #Where everything is kept

get '/' do #Main forum page
  @login = session[:username]
  @posts = []
  postdata = DB[:dataPost].where(:parentID => 0) # Passing in Front page render data and only grabs the original posts.
  postdata.each{ |row| @posts << [ row[:title], row[:postID], row[:author] ] }
  erb :index
end

post '/' do
  #we have a few things in params[] title and text
  id = (DB[:dataPost].map(:postID)).max + 1
  DB[:dataPost].insert( :parentID => 0, :postID => id, :title => params[:title], :text => params[:text], :author => session[:username] )
  redirect '/'
end #parent ID for posting to this is always 0 as it's an original post and must appear on the front page. The only thing that is rather tough to grab is post ID, but we'll create that like me grab a new user ID

get '/thread' do
  original = ( DB[:dataPost].where( :postID => params[:thread] ) ) #this points to a hash with title author and text as the significant fields.
  original.each do |x| @op = [ x[:author], x[:title], x[:text] ]
  end
#  @comments = []
#  postdata = DB[:dataPost].where( :parentID => params[:thread] )
#  postdata.each do |row| @comments << [ row[:author], row[:text] ];
#  end
  @thread = params[:thread]
  @posts = []
  postdata = DB[:dataPost].where(:parentID => params[:thread])
  postdata.each{ |row| @posts <<  [ row[:text], row[:author] ] }
  erb :thread
end

post '/thread' do
  if session[:username] != nil
    id = (DB[:dataPost].map(:postID)).max + 1
    DB[:dataPost].insert(:author => session[:username], :text => params[:text], :parentID => params[:thread], :postID => id) #CREATE METHOD FOR FINDING NEXT ID
  end
  redirect '/thread?thread=' + params[:thread]
end

get '/signup' do #account creation
  erb :signup
end

post '/signup' do #checks if form data is valid and creates account or asks to retry
  usernames = DB[:dataUser].map(:username)
  if usernames.include?(params[:user])
    @status = 'Signup Failed' #on invalid form data send back to signup to retry
    erb :signup
  else
    id = DB[:dataUser].map(:userID) #on valid form data
    id = id.max + 1
    DB[:dataUser].insert(:userID => id, :username => params[:user], :password =>params[:pass])
    redirect '/login'
  end
end

get '/login' do #account login
  erb :login
end

post '/login' do
  login_data = DB[:dataUser].to_hash(:username, :password) # Need to check for a more efficient way to do this bit
  #create hash from current DB user data table and check whether the given username in the table points to the given password
  if login_data[params[:user]] == params[:pass]
    session[:username] = params[:user] # only cookie necessary is who a user is, which let's me grab all of the information. Need a SECRET encoded cokie
    redirect '/'
  else
    @status = 'Login Failed' # I pass a string here because passing in true or false makes the erb for this much more complicated than it needs to be
  end
  erb :login
end

get '/logout' do #logs user out by removing cookie
  session[:username] = nil
  redirect '/'
end