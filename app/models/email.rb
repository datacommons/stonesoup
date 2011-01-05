class Email < ActionMailer::Base
  cattr_accessor :website_base_url
  def invite_for_org(user, org)
    recipients user.login
    from       "Data Commons Project <no-reply@dcp.usworker.coop>"
    subject    "You have been invited to become a Data Commons organization editor"
    body       :user => user, :organization => org
  end
  
  def update_notification(user, org)
    recipients user.login
    from "Data Commons Project <no-reply@dcp.usworker.coop>"
    subject "The entry '#{org.name}' has been updated."
    body :user => user, :organization => org
  end
end
