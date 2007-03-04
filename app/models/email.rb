class Email < ActionMailer::Base
  def invite_for_member(user, member)
    recipients user.login
    from       "no-reply@dcp.usworker.coop"
    subject    "You have been invited to a Data Commons member organization"
    body       :user => user, :member => member
  end
end
