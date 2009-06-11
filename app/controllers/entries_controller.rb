class EntriesController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy, :become_editor, :show]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @entry_pages, @entries = paginate :entries, :per_page => 10
  end

  def show
    @entry = Entry.find(params[:id])
    if not(@entry.latitude)
      @entry.save_ll
      @entry.save
    end
    respond_to do |format| 
      format.html
      format.xml { render :xml => @entry }
      format.csv do
        send_data Entry.report_table.to_csv,
        :type => 'text/csv; charset=iso-8859-1; header=present',
        :disposition => ("attachment; filename=" + params[:id] + ".csv")
      end
    end
  end

  def new
    @entry = Entry.new
  end

  def create
    @entry = Entry.new(params[:entry])

    if current_user.member
      if params[:make_entry_private]
        @entry.member = current_user.member
      else
        @entry.member = nil
      end
    end

    if @entry.save
      @entry.users << current_user if params[:associate_user_to_entry]

      flash[:notice] = 'Entry was successfully created.'
      redirect_to :controller => 'search', :action => 'search'
    else
      render :action => 'new'
    end
  end

  def edit
    @entry = Entry.find(params[:id])
  end

  def update
    @entry = Entry.find(params[:id])

    if current_user.member
      if params[:make_entry_private]
        @entry.member = current_user.member
      else
        @entry.member = nil
      end
    end

    if @entry.update_attributes(params[:entry])
      flash[:notice] = 'Entry was successfully updated.'
      redirect_to :action => 'show', :id => @entry
    else
      render :action => 'edit'
    end
  end

  def destroy
    Entry.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def become_editor
    @entry = Entry.find(params[:id])
    if request.method == :post
      @entry.users << current_user
      flash[:notice] = "You are now an editor for entry: #{@entry.name}"
      redirect_to :action => 'show', :id => @entry
    end
  end

  def invite
    @entry = Entry.find(params[:id])
    @user = User.find_by_login(params[:user_login])
    unless @user
      @user = User.create(:login => params[:user_login])
      @user.password_cleartext = `pwgen -a 6 1`.chomp
    end
    @user.entries << @entry
    @user.save!
    Email.deliver_invite_for_entry(@user, @entry)
    flash[:notice] = "#{@user.login} has been invited"
    redirect_to :action => 'show', :id => @entry
  end

  protected

  def authorize?(user)
    return true if current_user.is_admin?

    if %w[show edit update destroy become_editor invite].include? action_name
      entry = Entry.find(params[:id])
      if entry.member
        return entry.member == current_user.member
      end
    end

    true
  end

  def protect?(action)
    if action_name == 'show'
      entry = Entry.find(params[:id])
      return entry.member
    end

    true
  end

end
