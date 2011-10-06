class Email < ActionMailer::Base
  cattr_accessor :website_hostname
  def Email.website_base_url
    #logger.debug("Email.website_base_url: Email.website_hostname=#{Email.website_hostname.inspect}")
    'http://' + Email.website_hostname
  end
  def invite_for_org(user, org)
    recipients user.login
    from       "Data Commons Project <no-reply@dcp.usworker.coop>"
    subject    "You have been invited to become a Data Commons organization editor"
    body       :user => user, :organization => org
  end
  
  def update_notification(user, org, change_msg)
    recipients user.login
    from "Data Commons Project <no-reply@dcp.usworker.coop>"
    subject "The entry '#{org.name}' has been updated."
    body :user => user, :organization => org, :change_msg => change_msg
    body[:by_line] = " by #{User.current_user.login}" unless User.current_user.nil?
  end
  
  def password_reset(user, password_cleartext)
    recipients user.login
    from "Data Commons Project <no-reply@dcp.usworker.coop>"
    subject "Password reset for #{user.login}"
    body :user => user, :password => password_cleartext
  end
  
  def optin_confirmation(organization)
    organization.import_notice_sent_at = Time.now # do this first so it's part of the changes saved in the next step
    organization.reset_email_response_token!  # generate unique token and save record
    recipients organization.email
    from "Data Commons Project <no-reply@dcp.usworker.coop>"
    subject "Would you like to be included in the DCP Cooperative Directory?"
    content_type  "text/html"
    body :organization => organization
  end
  
  def optout_notification(organization)
    organization.import_notice_sent_at = Time.now # do this first so it's part of the changes saved in the next step
    organization.reset_email_response_token!  # generate unique token and save record
    recipients organization.email
    from "Data Commons Project <no-reply@dcp.usworker.coop>"
    subject "Your organization has been included in the DCP Cooperative Directory"
    content_type  "text/html"
    body :organization => organization
  end
  
end
