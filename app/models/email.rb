class Email < ApplicationRecord
  has_many_attached :attachments

  after_create_commit :broadcast_email

  def broadcast_email
    broadcast_prepend_later_to(
      "emails",
      target: "emails_list",
      partial: "emails/inbox",
      locals: { email: self }
    )
  end
end
