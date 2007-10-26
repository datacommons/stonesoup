class MembersController < ApplicationController
  before_filter :login_required

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @members = Member.find(:all)
  end

  def show
    @member = Member.find(params[:id])
  end

  def new
    @member = Member.new
  end

  def create
    @member = Member.new(params[:member])
    if @member.save
      flash[:notice] = 'Member was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @member = Member.find(params[:id])
  end

  def update
    @member = Member.find(params[:id])
    if @member.update_attributes(params[:member])
      flash[:notice] = 'Member was successfully updated.'
      redirect_to :action => 'show', :id => @member
    else
      render :action => 'edit'
    end
  end

  def destroy
    Member.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def invite
    @member = Member.find(params[:id])
    @user = User.find_by_login(params[:user_login])
    unless @user
      @user = User.create(:login => params[:user_login])
      @user.password_cleartext = `pwgen -a 6 1`.chomp
    end
    @user.member = @member
    @user.save!
    Email.deliver_invite_for_member(@user, @member)
    flash[:notice] = "#{@user.login} has been invited"
    redirect_to :action => 'show', :id => @member
  end

  protected

  def authorize?(user)
    return true if user.is_admin?

    if ['show', 'invite'].include? action_name
      current_user.member_id == params[:id].to_i
    end # otherwise returns nil
  end
end
