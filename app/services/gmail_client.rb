# frozen_string_literal: true

class GmailClient
  attr_reader :standard_fields, :service, :user

  def initialize(oauth_user)
    @user = oauth_user
    @service = oauth_user.email_service
    @user_id = 'me'
    @standard_fields = 'id, snippet, payload(headers, parts.parts.parts(mimeType, body.data))'
    @valuable_headers = %w[From To Subject Date]
    @valuable_mime_part = 'text/plain'

    # @kindful_client = KindfulClient.new
  end

  def batch_get_latest_messages(after:, before:)
    # AND handle pagination
    response = list_latest_messages(after: after, before: before)
    ids = response.message.map(&:id)

    @service.batch do |gmail|
      ids.each do |id|
        resp = trim_response gmail.get_user_message(@user_id, id, fields: @standard_fields)
        Email.from_gmail(resp, @user)
      end
    end
  end

  def batch_get_queried_messages(query: nil)
    # AND handle pagination
    response = list_queried_messages(query: query)
    ids = response.messages.map(&:id)

    @service.batch do |gmail|
      ids.each do |id|
        resp = trim_response gmail.get_user_message(@user_id, id, fields: @standard_fields)
        Email.from_gmail(resp, @user)
      end
    end
  end

  def list_latest_messages(after:, before:)
    # https://github.com/googleapis/google-api-ruby-client/blob/master/generated/google/apis/gmail_v1/service.rb#L944
    # AND handle pagination
    # q: 'after:2020/11/9 before:2020/11/10'
    @service.list_user_messages(@user_id, include_spam_trash: false, q: "after:#{after} before:#{before}")
  end

  def list_queried_messages(query: nil)
    # https://github.com/googleapis/google-api-ruby-client/blob/master/generated/google/apis/gmail_v1/service.rb#L944
    # AND handle pagination
    @service.list_user_messages(@user_id, include_spam_trash: false, q: query)
  end

  def get_message(message_id)
    # https://github.com/googleapis/google-api-ruby-client/blob/master/generated/google/apis/gmail_v1/service.rb#L783
    # AND check on batching
    trim_response @service.get_user_message(@user_id, message_id, fields: @standard_fields)
    # message = response.parsed_somehow
    # skip if To && From are both `@20liters.org`
    # HOW to handle messages sent to both users?
    # @kindful_client.import_user_w_email_note(message)
  end

  def refresh_authorization!
    # TODO: call this if @service returns an error and retry
    @user.refresh_authorization!
  end

  def trim_response(response)
    response.payload.headers.keep_if { |header| @valuable_headers.include? header.name }
    response.payload.parts[0].parts[0].parts.keep_if { |obj| obj.mime_type == @valuable_mime_part }

    response
  end
end
