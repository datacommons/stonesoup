class Email < ActionMailer::Base
  cattr_accessor :website_hostname
  FROM_ADDRESS = "Data Commons Project <no-reply@dcp.usworker.coop>"
  
  def Email.website_base_url
    #logger.debug("Email.website_base_url: Email.website_hostname=#{Email.website_hostname.inspect}")
    'http://' + Email.website_hostname
  end
  def invite_for_org(user, org)
    recipients user.login
    from       FROM_ADDRESS
    subject    "You have been invited to become a Data Commons organization editor"
    body       :user => user, :organization => org
  end
  
  def update_notification(user, org, change_msg, type = :update)
    recipients user.login
    from FROM_ADDRESS
    if type == :update
      body[:updated_or_removed] = 'updated'
    elsif type == :delete
      body[:updated_or_removed] = 'removed'
    else
      raise "Unknown update type '#{type}'"
    end
    subject "The entry '#{org.name}' has been #{body[:updated_or_removed]}."
    body[:organization] = org
    body[:change_msg] = change_msg
    body[:type] = type
    body[:by_line] = " by #{User.current_user.login}" unless User.current_user.nil?
    body[:why_notified] = 'for which you are an editor'
  end
  
  def dso_update_notification(dso, org, change_msg, type = :update)
    dso_recipients = dso.users.select{|u| u.update_notifications_enabled?}  # only send to DSO editors who have notifications enabled
    return false if dso_recipients.empty? # no users to send to, abort
    recipients dso_recipients
    from FROM_ADDRESS
    if type == :update
      body[:updated_or_removed] = 'updated'
      subject "Entry update notification & approval request"
    elsif type == :delete
      subject "Entry removal notification"
      body[:updated_or_removed] = 'removed'
    else
      raise "Unknown update type '#{type}'"
    end
    body[:organization] = org
    body[:change_msg] = change_msg
    body[:type] = type
    body[:by_line] = " by #{User.current_user.login}" unless User.current_user.nil?
    body[:why_notified] = 'in the data pool of ' + dso.name
    body[:dso] = dso
    body[:dso_extra] = "#{dso.name} has #{dso.num_unverified} entries pending verification."
    template "update_notification"  # use the same notification template as the main update notification e-mail
  end
  
  def password_reset(user, password_cleartext)
    recipients user.login
    from FROM_ADDRESS
    subject "Password reset for #{user.login}"
    body :user => user, :password => password_cleartext
  end
  
  def optin_confirmation(sender, organization)
    organization.import_notice_sent_at = Time.now # do this first so it's part of the changes saved in the next step
    organization.reset_email_response_token!  # generate unique token and save record
    recipients organization.email
    from sender
    subject "Would you like to be included in the DCP Cooperative Directory?"
    content_type  "text/html"
    body :organization => organization
  end
  
  def optout_notification(sender, organization)
    organization.import_notice_sent_at = Time.now # do this first so it's part of the changes saved in the next step
    organization.reset_email_response_token!  # generate unique token and save record
    recipients organization.email
    from sender
    subject "Your organization has been included in the DCP Cooperative Directory"
    content_type  "text/html"
    body :organization => organization
  end
  
end
