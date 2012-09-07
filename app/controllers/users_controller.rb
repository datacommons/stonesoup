class UsersController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy, :index, :list, :show, :prefs, :update_prefs]
  before_filter :admin_required, :only => [:index, :list, :new, :create, :edit, :update, :destroy]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update, :update_prefs ],
         :redirect_to => { :action => :list }

  def login
    case request.method
      when :post
        if params[:login] # attempting a login
          if session[:user] = User.authenticate(params['user_login'], params['user_password'])

            session[:user].update_attribute('last_login', DateTime.now)
            flash['notice']  = "Login successful"
            redirect_back_or_default :controller => 'search', :action => "index"
          else
            @login    = params['user_login']
            @message  = "Login unsuccessful"
          end
        elsif params[:forgot_pass] # requesting password reset
          if params[:user_login].blank?
            @login    = params['user_login']
            @message  = "Enter your e-mail address to reset your password."
          else
            user = User.find_by_login(params[:user_login])
            if user.nil?
              @login    = params['user_login']
              @message  = "No user was found with for that e-mail address."
            else
              # reset password and send e-mail
              newpass = Common::random_password(user.login)
              user.password_cleartext = newpass
              user.save!
              Email.deliver_password_reset(user, newpass)
              @message = "A new password was e-mailed to #{user.login} (if you don't see it, check your spam folder, or whitelist \"find.coop\")"
            end
          end
        end
    end
  end
  
  def signup
    case request.method
      when :post
        @user = User.new(params['user'])
        
        if @user.save
          logger.debug("user created with pass #{@user.password}, authenticating with pass #{params['user']['password_cleartext']}")
          session[:user] = User.authenticate(@user.login, params['user']['password_cleartext'])
          session[:user].update_attribute('last_login', DateTime.now)
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
    @users = User.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    @user.is_admin = params[:user][:is_admin] # must be set manually due to attr_protected
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

  def prefs
    @user = User.current_user
  end

  def update
    @user = User.find(params[:id])
    @user.is_admin = params[:user][:is_admin] # must be set manually due to attr_protected
    if @user.update_attributes(params[:user])
      flash[:notice] = 'User was successfully updated.'
      redirect_to :action => 'show', :id => @user
    else
      render :action => 'edit'
    end
  end

  def update_prefs
    @user = User.current_user
    if params[:user].nil? # bad form submission
      redirect_to :action => 'prefs' and return
    end
    params[:user].delete(:login) # not user-editable at this time. is_admin is already attr_protected
    params[:user].delete(:password_cleartext) if params[:user][:password_cleartext].blank?  # make sure password is not updated if left blank
    if @user.update_attributes(params[:user])
      flash[:notice] = 'Your preferences were successfully updated.'
      redirect_to :controller => 'search', :action => 'index'
    else
      render :action => 'prefs'
    end
  end
  
  def destroy
    User.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  protected

  def authorize?(user)
    return true if user.is_admin? # all access
    return true if params[:action].match('prefs$')  # user can edit own prefs
    return false  # otherwise, no
  end

end
