# frozen_string_literal: true

class GmailClient
  attr_reader :standard_fields, :service, :user, :body_data, :skipped_ids, :fails, :oauth_fail

  def initialize(oauth_user)
    @user = oauth_user
    @service = oauth_user.email_service
    @user_id = 'me'
    @standard_fields = 'id, snippet, payload(headers, mimeType, body.data, parts(mimeType, body.data, parts(mimeType, body.data, parts(mimeType, body.data, parts(mimeType, body.data)))))'
    @valuable_headers = %w[from to subject date message-id]
    @body_data = nil

    @skipped_ids = []
    @fails = []
    @oauth_fail = oauth_user.oauth_error_message

    return if oauth_user.oauth_error_message.present?

    refresh_authorization!
  end

  def batch_get_latest_messages(after:, before:)
    batch_get_queried_messages(query: "after:#{after} before:#{before}")
  end

  def batch_get_messages(message_ids)
    @service.batch do |gmail|
      message_ids.each do |id|
        gmail.get_user_message(@user_id, id, fields: @standard_fields) do |response, error|
          if error.present?
            @skipped_ids << id
            @fails << { id: id, msg: error, source: 'batch_get_messages' }
            next
          end

          # trim_response sets @body_data as a string
          resp = trim_response response
          Email.from_gmail(resp, @body_data, @user)
        end
      end
    end
  end

  def batch_get_queried_messages(query:)
    paged_response = list_queried_messages(query: query)

    # TESTING: This is a likely source of the Heroku R14 memory leak
    puts "batch_get_queried_messages: response size: #{paged_response.as_json.size}"

    ids = []
    paged_response.each do |message|
      ids << message.id
    end

    @skipped_ids = []

    if ids.size > 10
      # paged_responses uses `@service.fetch_all` which can return more than 100 messages
      # however, the `@service.batch` for `get_user_message()` is limited to 100 messages
      # so, spit the IDs into arrays of 99 or less.

      # TESTING: maybe the Heroku R14 memory leaks are due to this???
      # if ids.size > 100
      # ids.each_slice(99).to_a.each { |chunk_ids| batch_get_messages(chunk_ids) }

      ids.in_groups_of(10).each { |chunk_ids| batch_get_messages(chunk_ids) }
    else
      batch_get_messages(ids)
    end

    return unless @skipped_ids.any?

    # retry without batching for skipped_ids
    @skipped_ids.each { |skipped_id| get_message(skipped_id) }

    puts @skipped_ids if @skipped_ids.any?
    puts @fails if @fails.any?
  end

  def find_body(part, target_mime_type)
    if part.mime_type == target_mime_type && part.body.present?
      @body_data = ActionView::Base.full_sanitizer.sanitize(part.body.data).squish
    elsif part.parts.present?
      part.parts.each do |sub_part|
        break if @body_data.present?

        find_body(sub_part, target_mime_type)
      end
    end
  end

  def get_message(message_id)
    # https://github.com/googleapis/google-api-ruby-client/blob/master/generated/google/apis/gmail_v1/service.rb#L783
    response = trim_response @service.get_user_message(@user_id, message_id, fields: @standard_fields)

    if response.nil?
      @skipped_ids << message_id
      @fails << { id: message_id, msg: 'failed to get response', source: 'get_message' }
    else
      result = Email.from_gmail(response, @body_data, @user)
      @fails << { id: message_id, msg: 'failed to save', source: 'get_message' } if result.nil?
    end

    puts @fails if @fails.any?

    response
  end

  def list_latest_messages(after:, before:)
    list_queried_messages(query: "after:#{after} before:#{before}")
  end

  def list_queried_messages(query:)
    # https://github.com/googleapis/google-api-ruby-client/blob/master/generated/google/apis/gmail_v1/service.rb#L944
    @service.fetch_all(items: :messages) do |token|
      @service.list_user_messages(@user_id, include_spam_trash: false, q: query, page_token: token)
    end
  end

  def refresh_authorization!
    @user.refresh_authorization!
  end

  # Unused
  def see_message(message_id)
    @service.get_user_message(@user_id, message_id, fields: @standard_fields)
  end

  def trim_response(response)
    return unless response

    # not everyone capitalizes headers the same way: "Message-ID" vs. "Message-Id"
    response.payload.headers.keep_if { |header| @valuable_headers.include? header.name.downcase }

    @body_data = nil

    # singlepart emails have no 'parts', just have a 'body.data'
    # which can be 'text/plain' OR 'text/html'
    if response.payload.body&.data.present?
      # TESTING: This is a likely source of the Heroku R14 memory leak
      @body_data = ActionView::Base.full_sanitizer.sanitize(response.payload.body.data).squish
    elsif response.payload.parts&.any?
      # multipart emails have 'parts', which can be nested within parts multiple times
      # eventually, we'll find a body.data with the email body.
      # First try to find 'text/string' version of body.data
      response.payload.parts.each do |part|
        break if @body_data.present?

        find_body(part, 'text/string')
      end

      # didn't find 'text/string' body.data
      # so try again for 'text/html' body.data
      if @body_data.nil?
        response.payload.parts.each do |part|
          break if @body_data.present?

          find_body(part, 'text/html')
        end
      end

      response.payload.parts.clear if @body_data.present?
    end

    response
  end
end
