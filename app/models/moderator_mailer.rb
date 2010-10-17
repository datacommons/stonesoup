class ModeratorMailer < ActionMailer::Base

  def mail(recipient)     
    @from = "test@example.com"     
    @recipients = recipient     
    @subject = "Hi #{recipient}"     
    @body[:recipient] = recipient   
  end  

end
