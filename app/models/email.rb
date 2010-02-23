class Email < ActionMailer::Base
  def invite_for_member(user, member)
    recipients user.login
    from       "Data Commons Project <no-reply@dcp.usworker.coop>"
    subject    "You have been invited to a Data Commons member organization"
    body       :user => user, :member => member
  end

  def invite_for_org(user, entry)
    recipients user.login
    from       "Data Commons Project <no-reply@dcp.usworker.coop>"
    subject    "You have been invited to become a Data Commons entry editor"
    body       :user => user, :entry => entry
  end
end
