class Email < ActionMailer::Base
  def invite_for_org(user, org)
    recipients user.login
    from       "Data Commons Project <no-reply@dcp.usworker.coop>"
    subject    "You have been invited to become a Data Commons organization editor"
    body       :user => user, :organization => org
  end
end
