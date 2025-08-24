require 'base64'
require 'mail'

class SesProxyController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    action = params[:Action] || detect_action(request.path, request.query_string)
    parsed_email = extract_raw_email

    email = Email.create!(
      action: action,
      source: parsed_email[:source] || params[:Source],
      destination: parsed_email[:destination] || extract_destination,
      subject: parsed_email[:subject] || params.dig(:'Message.Subject.Data'),
      body_text: parsed_email[:body_text] || params.dig(:'Message.Body.Text.Data'),
      body_html: parsed_email[:body_html] || params.dig(:'Message.Body.Html.Data'),
      raw_email: parsed_email[:raw_email] || params[:'RawMessage.Data']
    )

    if parsed_email[:attachments].present?
      parsed_email[:attachments].each do |attachment|
        email.attachments.attach(
          io: StringIO.new(attachment[:data]),
          filename: attachment[:filename],
          content_type: attachment[:mime_type]
        )
      end
    end

    render xml: <<~XML
      <SendRawEmailResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
        <SendRawEmailResult>
          <MessageId>fake-message-id-#{email.id}</MessageId>
        </SendRawEmailResult>
        <ResponseMetadata>
          <RequestId>fake-request-id</RequestId>
        </ResponseMetadata>
      </SendRawEmailResponse>
    XML
  end

  private

  def detect_action(path, query)
    return "SendEmail" if path.include?("SendEmail") || query.include?("SendEmail")
    return "SendRawEmail" if path.include?("SendRawEmail") || query.include?("SendRawEmail")
    "Unknown"
  end

  def extract_destination
    {
      to: params[:"Destination.ToAddresses.member.1"],
      cc: params[:"Destination.CcAddresses.member.1"],
      bcc: params[:"Destination.BccAddresses.member.1"]
    }.to_json
  end

  def extract_raw_email
    raw_data = params[:'RawMessage.Data']
    return {} unless raw_data

    decoded_param = CGI.unescape(raw_data)
    raw_email_string = Base64.decode64(decoded_param)

    mail = Mail.read_from_string(raw_email_string)

    attachments = mail.attachments.map do |att|
      {
        filename: att.filename,
        mime_type: att.mime_type,
        data: att.body.decoded
      }
    end

    {
      source: mail.from&.join(', '),
      destination: { to: mail.to, cc: mail.cc, bcc: mail.bcc }.to_json,
      subject: mail.subject,
      body_text: mail.text_part&.decoded || mail.body.decoded,
      body_html: mail.html_part&.decoded,
      raw_email: raw_email_string,
      attachments: attachments
    }
  end
end
