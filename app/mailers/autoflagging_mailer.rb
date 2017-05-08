class AutoflaggingMailer < ApplicationMailer
  default from: 'MS Autoflagger <metasmoke@erwaysoftware.com>'

  def setting_changed(setting, editor)
    @setting = setting
    @editor = editor

    # mail(bcc: User.with_role(:admin).pluck(:email).join('; '), subject: "[Autoflagging] #{@editor.username} edited #{@setting.name}")
  end
end
