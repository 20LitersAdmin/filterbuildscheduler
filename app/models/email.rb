# frozen_string_literal: true

class Email < ApplicationRecord
  belongs_to :oauth_user

  validates :message_id, :google_id, uniqueness: true

  def self.from_gmail(response, oauth_user)
    message_id = response.headers.select { |header| header.name == 'Message-ID' }.first.value
    email =
      where(google_id: response.id, message_id: message_id, oauth_user: oauth_user).first_or_initialize.tap do |e|
        e.oauth_user = oauth_user
        e.from       = response.headers.select { |header| header.name == 'From' }.first.value
        e.to         = response.headers.select { |header| header.name == 'To' }.first.value
        e.subject    = response.headers.select { |header| header.name == 'Subject' }.first.value
        e.date       = DateTime.parse(response.headers.select { |header| header.name == 'Date' }.first.value)
        e.body       = response.payload.parts[0].parts[0].parts.first.body.data
      end

    email.save
    email.reload
  end
end

=begin
#<Google::Apis::GmailV1::Message:0x00007f8ae838f778
  @id="175aee26de8209d2",
  @payload=#<Google::Apis::GmailV1::MessagePart:0x00007f8ae838cc80
    @headers=
      [
        #<Google::Apis::GmailV1::MessagePartHeader:0x00007f8ae83bbcb0 @name="From", @value="\"James H. Quist CPA\" <jquist@quist-cpa.com>">,
        #<Google::Apis::GmailV1::MessagePartHeader:0x00007f8ae83bb620 @name="To", @value="\"'Brianna Eiermann'\" <briannae@nfgllc.com>, \"'Chip Kragt'\" <chip@20liters.org>, \"'Ben Lyzenga'\" <BenL@nfgllc.com>">,
        #<Google::Apis::GmailV1::MessagePartHeader:0x00007f8ae83baf90 @name="References", @value="<007501d6ae1e$b52549a0$1f6fdce0$@quist-cpa.com> <c72935b6ff2347e0ad492682a8effaaf@nfgllc.com>">,
        #<Google::Apis::GmailV1::MessagePartHeader:0x00007f8ae83ba900 @name="In-Reply-To", @value="<c72935b6ff2347e0ad492682a8effaaf@nfgllc.com>">,
        #<Google::Apis::GmailV1::MessagePartHeader:0x00007f8ae83ba270 @name="Subject", @value="RE: 20L Financial Statements Draft">,
        #<Google::Apis::GmailV1::MessagePartHeader:0x00007f8ae83b9be0 @name="Date", @value="Mon, 9 Nov 2020 16:20:40 -0500">,
        #<Google::Apis::GmailV1::MessagePartHeader:0x00007f8ae83b9550 @name="Message-ID", @value="<015601d6b6de$2d16eb40$8744c1c0$@quist-cpa.com>">
      ],
    @parts=
      [
        #<Google::Apis::GmailV1::MessagePart:0x00007f8ae83c3b18 @parts=
          [
            #<Google::Apis::GmailV1::MessagePart:0x00007f8ae83c2d08 @parts=
              [
                #<Google::Apis::GmailV1::MessagePart:0x00007f8ae83c1ef8 @body=
                  #<Google::Apis::GmailV1::MessagePartBody:0x00007f8ae83c1a98
                    @data="Good afternoon, Brianna!\r\n\r\n \r\n\r\nThanks for catching those allocation variances. I'm not sure why, but the\r\ncalculations weren't done consistently with how they've been done in the\r\npast. I fixed all those formulas so what you find in the attached should be\r\nmuch more comparative to the prior year. Let me know if there are any other\r\nquestions or concerns.\r\n\r\n \r\n\r\nJim\r\n\r\n \r\n\r\nJames H. Quist CPA, PLC\r\n\r\n2425 Avon Ave SW\r\n\r\nWyoming, MI 49519\r\n\r\n <tel:616-443-5344> 616-443-5344\r\n\r\n <http://www.quist-cpa.com/> www.QUIST-CPA.com\r\n\r\n\r\n\r\n \r\n\r\nNOTICE: The information in this e-mail is confidential and may be legally\r\nprivileged. It is intended solely for the addressee. Access to this e-mail\r\nby anyone else is unauthorized. If you are not the intended recipient, any\r\ndisclosure, copying, distribution or any action taken or omitted to be taken\r\nin reliance on it is prohibited and may be unlawful.\r\n\r\n \r\n\r\nFrom: Brianna Eiermann <briannae@nfgllc.com> \r\nSent: Monday, November 9, 2020 2:17 PM\r\nTo: James H. Quist CPA <jquist@quist-cpa.com>; 'Chip Kragt'\r\n<chip@20liters.org>; Ben Lyzenga <BenL@nfgllc.com>\r\nSubject: RE: 20L Financial Statements Draft\r\n\r\n \r\n\r\nHi Jim, \r\n\r\n \r\n\r\nI reviewed the financials with Chip and Ben and we have a question on\r\ndepartment allocations.  On the statement of functional expenses, we noticed\r\nthat Information Technology and Occupancy were allocated differently than\r\nlast fiscal year. Can you explain where this came from or why we are\r\nallocating them that way? If possible, Chip and I discussed keeping it\r\nconsistent with the prior fiscal year. \r\n\r\n \r\n\r\nBrianna Eiermann\r\n\r\nNienhuis Financial Group\r\n\r\n \r\n\r\nFrom: James H. Quist CPA <jquist@quist-cpa.com <mailto:jquist@quist-cpa.com>\r\n> \r\nSent: Thursday, October 29, 2020 2:10 PM\r\nTo: 'Chip Kragt' <chip@20liters.org <mailto:chip@20liters.org> >; Ben\r\nLyzenga <BenL@nfgllc.com <mailto:BenL@nfgllc.com> >; Brianna Eiermann\r\n<briannae@nfgllc.com <mailto:briannae@nfgllc.com> >\r\nSubject: 20L Financial Statements Draft\r\n\r\n \r\n\r\nGood afternoon, 20Literers!\r\n\r\n \r\n\r\nAttached is a draft of the financial statements for the 2020 fiscal year.\r\nPlease review and let me know if you have any questions or find something\r\nthat needs to be corrected.\r\n\r\n \r\n\r\nThanks!\r\n\r\n \r\n\r\nJim\r\n\r\n \r\n\r\nJames H. Quist CPA, PLC\r\n\r\n2425 Avon Ave SW\r\n\r\nWyoming, MI 49519\r\n\r\n <tel:616-443-5344> 616-443-5344\r\n\r\n <http://www.quist-cpa.com/> www.QUIST-CPA.com\r\n\r\n\r\n\r\n \r\n\r\nNOTICE: The information in this e-mail is confidential and may be legally\r\nprivileged. It is intended solely for the addressee. Access to this e-mail\r\nby anyone else is unauthorized. If you are not the intended recipient, any\r\ndisclosure, copying, distribution or any action taken or omitted to be taken\r\nin reliance on it is prohibited and may be unlawful.\r\n\r\n \r\n\r\n">,
                    @mime_type="text/plain">
      ]>,
  @snippet="Good afternoon, Brianna! Thanks for catching those allocation variances. I&#39;m not sure why, but the calculations weren&#39;t done consistently with how they&#39;ve been done in the past. I fixed all">
=end
