class UsersController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy, :index, :list, :show]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def login
    case request.method
      when :post
        if session[:user] = User.authenticate(params['user_login'], params['user_password'])

          session[:user].update_attribute('last_login', DateTime.now)
          flash['notice']  = "Login successful"
          redirect_back_or_default :controller => 'search', :action => "index"
        else
          @login    = params['user_login']
          @message  = "Login unsuccessful"
      end
    end
  end
  
  def signup
    case request.method
      when :post
        @user = User.new(params['user'])
        
        if @user.save      
          session[:user] = User.authenticate(@user.login, params['user']['password'])
          flash['notice']  = "Signup successful"
          redirect_back_or_default :action => "welcome"          
        end
      when :get
        @user = User.new
    end      
  end  
  
  def delete
    if params['id'] and session[:user]
      @user = User.find(params['id'])
      @user.destroy
    end
    redirect_back_or_default :action => "welcome"
  end  
    
  def logout
    session[:user] = nil
  end
    
  def welcome
  end

  def list
    @user_pages, @users = paginate :users, :per_page => 10
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = 'User was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = 'User was successfully updated.'
      redirect_to :action => 'show', :id => @user
    else
      render :action => 'edit'
    end
  end

  def destroy
    User.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  protected

  def authorize?(user)
    user.is_admin?
  end

end
