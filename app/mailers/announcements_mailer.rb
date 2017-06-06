class AnnouncementsMailer < ApplicationMailer
  default from: 'MS Announcements <metasmoke@erwaysoftware.com>'

  def announce(announcement)
    @announcement = announcement
    users = User.where(announcement_emails: true).where.not('email IS NULL OR email = ""')
    emails = users.map(&:email)

    emails.each do |e|
      mail(to: e, subject: 'New metasmoke announcement')
    end
  end
end
