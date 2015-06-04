class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject << 'Please activate your new account'
    @body[:url] = "#{APP_CONFIG[:site_url]}/activate/#{user.activation_code}"
  end
  
  def activation(user)
    setup_email(user)
    @subject << 'Your account has been activated!'
    @body[:url] = APP_CONFIG[:site_url]
  end

  def export_notification(user, export)
    setup_email(user)
    @export = export
    subject = @export.export_type == Export::EXPORT_TYPE_USER ? "Your users export is ready!" : "Your schools and districts export is ready!"
    @subject << subject
    @body[:url] = APP_CONFIG[:site_url]
  end
  
  protected
  
  def setup_email(user)
    self.current_theme = (APP_CONFIG[:theme]||'default')
    @recipients = "#{user.email}"
    @from = APP_CONFIG[:help_email]
    @subject = "[#{APP_CONFIG[:site_name]}] "
    @sent_on = Time.now
    @body[:user] = user
  end
end
