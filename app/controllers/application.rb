# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require_dependency "login_system"

require 'sites'

class ApplicationController < ActionController::Base
  include LoginSystem

  helper ApplicationHelper

  before_filter :login_from_cookie, :set_current_user_on_model, :set_custom_filters, :check_for_map
  
  layout :custom_layout
  
private

protected

  def check_for_map
    @map_style = false
    if params[:style]
      if params[:style] == "map"
        @unlimited_search = true
        @map_style = true
      end
    end
  end


  def get_site
    site = Site.get_subsite(params[:site] || request.host)
    if site.nil?
      site = Site.get_subsite('find.coop') 
    end
    site
  end

  def custom_layout
    #return appropriate layout depending on value of request.host (domain name)
    # you can also do other dependent filtering, setting session variables, etc.
    if params[:widget]
      return 'bare'
    end
    if params[:iframe]
      logger.debug("setting session's IFRAME status to: #{params[:iframe]}")
      session[:iframe] = (params[:iframe].to_i == 1)
    end
    return @site.layout.to_s + "/template"
  end

public
  def set_custom_filters
    @site = get_site
    session[:state_filter] = @site.state_filter
    session[:city_filter] = @site.city_filter
    session[:zip_filter] = @site.zip_filter
    session[:dso_filter] = @site.dso_filter
    session[:org_type_filter] = @site.org_type_filter
    get_filters # session[:filter_active]
    
    Email.website_hostname = @site.canonical_name
    logger.debug("Set Email.website_hostname to: #{Email.website_hostname.inspect}")
  end

  def get_filters
    possible_filters = [
                        { :key => :country_filter, :label => "Country" },
                        { :key => :state_filter, :label => "State" },
                        { :key => :city_filter, :label => "City" },
                        { :key => :zip_filter, :label => "Zip" },
                        { :key => :loc_filter, :label => "Loc", :single => true },
                        { :key => :within_filter, :label => "Within", :single => true },
                        { :key => :dso_filter, :label => "Team" },
                        { :key => :org_type_filter, :label => "Organization Type" },
                        { :key => :sector_filter, :label => "Business Sector" },
                        { :key => :legal_structure_filter, :label => "Legal Structure" }
                       ]

    _params = params
    if _params[:reset]
      possible_filters.each do |f|
        name = ("active_" + f[:key].to_s).to_sym
        session[name] = nil
      end
    end
    if _params[:state]
      long_state = Location::STATE_SHORT[_params[:state]]
      long_state = _params[:state] unless long_state
      session[:active_state_filter] = long_state.split(/,/)
    end
    if _params[:city]
      session[:active_city_filter] = _params[:city].split(/,/)
    end
    if _params[:zip]
      session[:active_zip_filter] = _params[:zip].split(/,/)
    end
    if _params[:sector]
      session[:active_sector_filter] = _params[:sector].split(/;/)
    end
    if _params[:dso]
      session[:active_dso_filter] = _params[:dso].split(/;/)
    end
    if _params[:location_origin]
      if _params[:location_origin].blank?
        session[:active_loc_filter] = nil
      else
        session[:active_loc_filter] = [_params[:location_origin]]
      end
    end
    if _params[:within]
      if _params[:location_origin].blank?
        session[:active_within_filter] = nil
      else
        session[:active_within_filter] = [_params[:within]]
      end
    end
    if _params[:country]
      alt_form = Location::COUNTRY_SHORT[_params[:country]]
      alt_form = _params[:country] unless alt_form
      session[:active_country_filter] = alt_form.split(/,/)
    end
    @filter_unrestricted = _params[:unrestricted]

    default_filters = []
    active_filters = []
    @filter_bank = {}
    all_filters = []
    all_default = true
    possible_filters.each do |possible_filter|
      key = possible_filter[:key]
      name = key.to_s.gsub("_filter","")
      filter0 = filter = session[key]
      is_default = !filter.nil?
      has_default = is_default
      default_filters << { :name => name, :label => possible_filter[:label], :value => filter } if filter
      filter2 = session[("active_"+key.to_s).to_sym]
      if @filter_unrestricted
        filter2 = session[("active_"+key.to_s).to_sym] = [] if filter
        filter2 = session[("active_"+key.to_s).to_sym] = nil if filter2 and !filter
      end
      if filter2
        active_filters << { :name => name, :label => possible_filter[:label], :value => filter2 } 
        filter = filter2
        applicable = true
        if name == "within"
          if @filter_bank["loc"].blank?
            applicable = false
          else
            applicable = false if @filter_bank["loc"][:value].blank?
          end
        end
        if applicable
          all_default = false if has_default
          all_default = false unless filter2.blank?
          # puts "Not default because of #{name} (#{@filter_bank['loc'].inspect})"
        end
        is_default = false
      end
      f = { :name => name, :label => possible_filter[:label], :value => filter, :original => filter0, :is_default => is_default, :has_default => has_default, :single => possible_filter[:single] }
      all_filters << f
      @filter_bank[f[:name]] = f
    end
    default_filters.compact!
    active_filters.compact!
    @default_filters = default_filters
    @active_filters = active_filters
    @all_filters = all_filters
    @filter_override = !all_default
  end

  def valid_password?(password, username)
    return false unless password.match(/[A-Z]/)
    return false unless password.match(/[a-z]/)
    return false unless password.match(/[0-9\?\!\@\#\$\%\^\&\*\(\)\[\]\{\}\=\+\-]/)
    return false if password.downcase == username.downcase
    return false if password.match(/password/i)
    return true
  end
  
  PASSWORD_LENGTH = 6
  PASSWORD_CHARS = 'abcdefghijkmnopqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ23456789'
  def random_password(username)
    password = ''
    while(!valid_password?(password, username))
      password = ''
      PASSWORD_LENGTH.times do
        password += PASSWORD_CHARS[rand(PASSWORD_CHARS.length), 1]
      end
    end
    return password
  end
  	
  def current_user
    if session[:user] && session[:user].instance_of?( User ) then
      return session[:user]
    else
      return nil
    end
  end


  def merge_check
    if params[:trunk_id]
      if params[:trunk_id] != params[:branch_id]
        @organization1 = Organization.find(params[:trunk_id])
        @organization2 = Organization.find(params[:branch_id])
        @organization = @organization1
      end
    end
  end
 
  
  def set_current_user_on_model
    User.current_user = current_user
  end

  # if user is not logged in but user has a login token cookie, check
  # if login token hasn't expired and log the user in
  def login_from_cookie
    if current_user.nil? && cookies[:login]
      if (user = User.find_by_login_token(cookies[:login])) && 
          user.login_token_created_at > 14.days.ago
        # reset the token (shorter lifetimes = more secure) & reset the timer
        user.set_login_token
        cookies[:login] = {:value => user.login_token, 
          :expires => 14.days.from_now}
        session[:user] = user
      end
    end
  end


  def not_found
    respond_to do |type| 
      type.html { render :template => "errors/error_404", :status => 404 } 
      type.all  { render :nothing => true, :status => 404 } 
    end
    true  # so we can do "render_404 and return"
  end

  def show_tag_context(model)
    tc = TagContext.find_by_name(model.to_s)
    @title = model.to_s.underscore.pluralize.humanize unless tc
    @title = tc.friendly_name if tc
    @model = model
    @entries = model.find(:all, :order => 'name').paginate(:per_page => 300, :page => (params[:page]||1))
    respond_to do |format|
      format.html { render :template => 'search/search' }
      format.xml  { render :xml => @entries }
    end
  end

  def show_tag(tag)
    joinSQL, condSQLs, condParams = Organization.all_join(session)
    # joinSQL = nil if condSQLs.empty?
    @tag = tag
    @title = tag.name
    if joinSQL.nil?
      if tag.respond_to? "tags"
        results = tag.tags.map{|t| t.taggings}.flatten.map{|t| t.taggable}
      else
        results = tag.taggings.flatten.map{|t| t.taggable}
      end
    else
      # for now, let's assume we are tagging organizations only
      joinSQL = "#{joinSQL} INNER JOIN taggings AS taggings2 ON taggings2.taggable_id = organizations.id INNER JOIN tags AS tags2 ON taggings2.tag_id = tags2.id"
      if tag.respond_to? "root_id"
        condSQLs << "tags2.id = ?"
        condParams << tag.id
      else
        condSQLs << "tags2.root_id = ?"
        condSQLs << "tags2.root_type = ?"
        condParams << tag.id
        condParams << tag.class.to_s
      end
      conditions = []
      conditions = [condSQLs.collect{|c| "(#{c})"}.join(' AND ')] + condParams unless condSQLs.empty?
      results = Organization.find(:all, :conditions => conditions, :joins => joinSQL, :select => ApplicationHelper.get_org_select([]))
    end
    if tag.respond_to? "children"
      results = results + tag.children
    end
    if @unlimited_search
      @entries = results.paginate(:per_page => 50000, :page => 1)
    else
      @entries = results.paginate(:per_page => 15, :page => (params[:page]||1))
    end
    respond_to do |format|
      format.html { render :template => 'search/search' }
      format.xml  { render :xml => @entries }
    end
  end
end
