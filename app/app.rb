ENV['RACK_ENV'] ||= 'development'

require 'sinatra/base'
require 'sinatra/flash'
require 'tilt/erb'
require_relative 'data_mapper_setup'

class BookmarkManager < Sinatra::Base
  enable :sessions
  register Sinatra::Flash
  set :session_secret, 'super secret'
  set :public_folder, 'public'

  get '/' do
    erb(:sign_in)
  end

  post '/sign_in' do
    @user = User.authenticate(params[:email], params[:password])
    if @user
      session[:user_id] = @user.id
      redirect '/links'
    else
      flash.now[:errors] = 'Email address or Password incorrect'
      erb(:sign_in)
    end
  end

  get '/links' do
    @message = session.delete(:message)
    @links = Link.all
    erb :'links/index'
  end

  get '/links/new' do
    erb :'links/new'
  end

  post '/links' do
    link = Link.new(title: params[:title], url: params[:url])
    params[:tag].split(/[,+ *]+/).each do |tag_name|
      tag = Tag.first_or_create(name: tag_name)
      link.tags << tag
    end
    link.save
    session[:message] = 'Link successfully added'
    redirect '/links'
  end

  get '/tags/:name' do
    tag = Tag.first(name: params[:name])
    @links = tag ? tag.links : []
    erb :'links/index'
  end

  get '/register' do
    @user = User.new
    erb :register
  end

  post '/users' do
    @user = User.new(name: params[:name],
                    email: params[:email],
                    password: params[:password],
                    password_confirmation: params[:password_confirmation])
    if @user.save
      session[:user_id] = @user.id
      redirect to('/links')
    else
      flash.now[:password_error] = @user.errors[:password].first
      flash.now[:email_error] = @user.errors[:email].first

      erb :register
    end
  end

  post '/sign_out' do
    session.clear
    flash.next[:goodbye] = "Goodbye!"
    redirect '/'
  end

  helpers do
    def current_user
      @current_user ||= User.get(session[:user_id])
    end
  end

  # start the server if ruby file executed directly
  run! if app_file == $PROGRAM_NAME
end
