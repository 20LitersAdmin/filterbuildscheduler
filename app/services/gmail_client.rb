# frozen_string_literal: true

class GmailClient
  def initialize(oauth_user_service)
    @service = oauth_user_service
    @kindful_client = kindfulClient.new
  end

  def list_latest_messages
    # https://github.com/googleapis/google-api-ruby-client/blob/master/generated/google/apis/gmail_v1/service.rb#L944
    # @service.list_user_messages(user_id, include_spam_trash: nil, label_ids: nil, max_results: nil, page_token: nil, q: nil, fields: nil, quota_user: nil, options: nil, &block)
  end

  def get_message(message_id:)
    # https://github.com/googleapis/google-api-ruby-client/blob/master/generated/google/apis/gmail_v1/service.rb#L783
    # response = @service.get_user_message(user_id, id, format: nil, metadata_headers: nil, fields: nil, quota_user: nil, options: nil, &block)
    # message = response.parsed_somehow
    # @kindful_client.import_user_w_email_note(message)
  end

=begin
https://developers.google.com/gmail/api/guides/sync

  1. after:YYYY/MM/DD strategy:
  --> https://developers.google.com/gmail/api/reference/rest/v1/users.messages/list
  * save the 'last-run date' to the OauthUser's record
  * list all messages after a given date: users.messages.list(q: 'after:YYYY/MM/DD')
  * collect all message IDs <-- save them as an array (t.string 'tags', array: true) to check for repeats?
  * call `get` on all message IDs (or batch: )
  * parse message for: sender, receiver, subject, body
  * send each message to Kindful
  * update the last-run date on the OauthUser's record

  ### sample messages.list payload:
  {
    "messages": [
      {
        "id": "1759457da3a7a593",
        "threadId": "1759457da3a7a593"
      },
      {
        "id": "1759452131670d31",
        "threadId": "17575e6093ed043e"
      },
      {
        "id": "1759446861338dec",
        "threadId": "17570c0c2abba776"
      },
      {
        "id": "175943c41757930e",
        "threadId": "1757a5438f6a6b1b"
      },
      {
        "id": "175943808dfb1083",
        "threadId": "174df8b54ee4e2da"
      },
      {
        "id": "175941893bf75154",
        "threadId": "175941893bf75154"
      },
      {
        "id": "1759400bd1297856",
        "threadId": "1759400bd1297856"
      },
      {
        "id": "17593fcb8d7fb0e6",
        "threadId": "17593fcb8d7fb0e6"
      },
      {
        "id": "17593e5f87e7caab",
        "threadId": "17593ccb985185be"
      },
      {
        "id": "17593e16dda506dd",
        "threadId": "17593ccb985185be"
      },
      {
        "id": "17593da762dd6b35",
        "threadId": "17593ccb985185be"
      },
      {
        "id": "17593d8be20c7210",
        "threadId": "17593ccb985185be"
      },
      {
        "id": "17593d6a894d936e",
        "threadId": "17593d2cf8b3e348"
      },
      {
        "id": "17593d68a483b60b",
        "threadId": "17593ccb985185be"
      },
      {
        "id": "17593d21bcf3a509",
        "threadId": "1758a2b0a158a346"
      },
      {
        "id": "17593ccb985185be",
        "threadId": "17593ccb985185be"
      },
      {
        "id": "17593ca141145594",
        "threadId": "17593ca141145594"
      },
      {
        "id": "17593c9c8307d0b7",
        "threadId": "17593c9c8307d0b7"
      },
      {
        "id": "17593c8e4c96ebd1",
        "threadId": "17593c8e4c96ebd1"
      },
      {
        "id": "17593c864344104c",
        "threadId": "17593c04f2bdb559"
      },
      {
        "id": "17593c43a7a6bbf1",
        "threadId": "1755bb517f0755da"
      },
      {
        "id": "17593c41e72cbe31",
        "threadId": "17593c41e72cbe31"
      },
      {
        "id": "17593c3a20af6b47",
        "threadId": "17593c3a20af6b47"
      },
      {
        "id": "17593c04f2bdb559",
        "threadId": "17593c04f2bdb559"
      },
      {
        "id": "17593bdebb4349c9",
        "threadId": "1758aaf0c3f114ce"
      },
      {
        "id": "17593b4c68c00862",
        "threadId": "1750e35c14021488"
      },
      {
        "id": "17593b48f8be6f84",
        "threadId": "17593b48f8be6f84"
      },
      {
        "id": "17593ae9b619832c",
        "threadId": "17593a7c1a04e6d7"
      },
      {
        "id": "17593aa3e785a4a2",
        "threadId": "17593aa3e785a4a2"
      },
      {
        "id": "17593a7c1a04e6d7",
        "threadId": "17593a7c1a04e6d7"
      },
      {
        "id": "175939d52b564f5b",
        "threadId": "175939d52b564f5b"
      },
      {
        "id": "1759392eff1b9304",
        "threadId": "1759392eff1b9304"
      },
      {
        "id": "175937558e505fff",
        "threadId": "175937558e505fff"
      },
      {
        "id": "1759350d2711a9b2",
        "threadId": "1759350d2711a9b2"
      },
      {
        "id": "1759327b7578e34f",
        "threadId": "1759327b7578e34f"
      },
      {
        "id": "175930020631e5c0",
        "threadId": "175930020631e5c0"
      },
      {
        "id": "17592eb201aee176",
        "threadId": "17592eb201aee176"
      },
      {
        "id": "17591ebf609bddd0",
        "threadId": "174df8b54ee4e2da"
      },
      {
        "id": "1759116e0a5a1473",
        "threadId": "1758e6d147effab2"
      }
    ],
    "resultSizeEstimate": 39
  }

  2. History based-strategy:
  --> https://developers.google.com/gmail/api/reference/rest/v1/users.history
  * check OauthUser's current historyID against users.getProfile
  * proceed if users.getProfile[historyId] > OauthUser.last_history_id
  * list all histories since OauthUser's last_history_id
  * collect all messagesAdded message IDs
  * call `get` on all message IDs
  * parse message for: sender, receiver, subject, body

  ### sample getProfile payload:
  {
    "emailAddress": "chip@20liters.org",
    "messagesTotal": 57501,
    "threadsTotal": 25378,
    "historyId": "9063342"
  }

  ### sample history payload:
  {
    "history": [
      {
        "id": "9051947",
        "messages": [
          {
            "id": "17593c85ab6ecb52",
            "threadId": "17593c04f2bdb559"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593c85ab6ecb52",
              "threadId": "17593c04f2bdb559",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9051958",
        "messages": [
          {
            "id": "17593c864344104c",
            "threadId": "17593c04f2bdb559"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593c864344104c",
              "threadId": "17593c04f2bdb559",
              "labelIds": [
                "SENT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052045",
        "messages": [
          {
            "id": "17593c8e4c96ebd1",
            "threadId": "17593c8e4c96ebd1"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593c8e4c96ebd1",
              "threadId": "17593c8e4c96ebd1",
              "labelIds": [
                "CATEGORY_PROMOTIONS",
                "UNREAD"
              ]
            }
          }
        ]
      },
      {
        "id": "9052098",
        "messages": [
          {
            "id": "17593c9c8307d0b7",
            "threadId": "17593c9c8307d0b7"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593c9c8307d0b7",
              "threadId": "17593c9c8307d0b7",
              "labelIds": [
                "UNREAD",
                "IMPORTANT",
                "CATEGORY_PERSONAL",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9052160",
        "messages": [
          {
            "id": "17593ca141145594",
            "threadId": "17593ca141145594"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593ca141145594",
              "threadId": "17593ca141145594",
              "labelIds": [
                "UNREAD",
                "IMPORTANT",
                "CATEGORY_UPDATES",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9052235",
        "messages": [
          {
            "id": "17593ccb985185be",
            "threadId": "17593ccb985185be"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593ccb985185be",
              "threadId": "17593ccb985185be",
              "labelIds": [
                "UNREAD",
                "IMPORTANT",
                "CATEGORY_PERSONAL",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9052563",
        "messages": [
          {
            "id": "17593d1579eb5de2",
            "threadId": "1758a2b0a158a346"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d1579eb5de2",
              "threadId": "1758a2b0a158a346",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052574",
        "messages": [
          {
            "id": "17593d17871c71d3",
            "threadId": "1758a2b0a158a346"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d17871c71d3",
              "threadId": "1758a2b0a158a346",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052583",
        "messages": [
          {
            "id": "17593d1c523e7ead",
            "threadId": "1758a2b0a158a346"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d1c523e7ead",
              "threadId": "1758a2b0a158a346",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052592",
        "messages": [
          {
            "id": "17593d205564d5e2",
            "threadId": "1758a2b0a158a346"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d205564d5e2",
              "threadId": "1758a2b0a158a346",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052601",
        "messages": [
          {
            "id": "17593d217ef7d2f8",
            "threadId": "1758a2b0a158a346"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d217ef7d2f8",
              "threadId": "1758a2b0a158a346",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052610",
        "messages": [
          {
            "id": "17593d21bcf3a509",
            "threadId": "1758a2b0a158a346"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d21bcf3a509",
              "threadId": "1758a2b0a158a346",
              "labelIds": [
                "SENT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052671",
        "messages": [
          {
            "id": "17593d2cf8b3e348",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d2cf8b3e348",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052683",
        "messages": [
          {
            "id": "17593d3184d487ba",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d3184d487ba",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052691",
        "messages": [
          {
            "id": "17593d34c507d792",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d34c507d792",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052699",
        "messages": [
          {
            "id": "17593d392a8b29c0",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d392a8b29c0",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052707",
        "messages": [
          {
            "id": "17593d3caa5c4e7f",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d3caa5c4e7f",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052715",
        "messages": [
          {
            "id": "17593d42e91f6fd5",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d42e91f6fd5",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052723",
        "messages": [
          {
            "id": "17593d44076e6909",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d44076e6909",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052731",
        "messages": [
          {
            "id": "17593d4526943615",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d4526943615",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052739",
        "messages": [
          {
            "id": "17593d4778e5a88d",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d4778e5a88d",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052747",
        "messages": [
          {
            "id": "17593d48a528cde4",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d48a528cde4",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052755",
        "messages": [
          {
            "id": "17593d4a063b28b3",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d4a063b28b3",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052763",
        "messages": [
          {
            "id": "17593d4cef355ffc",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d4cef355ffc",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052771",
        "messages": [
          {
            "id": "17593d50a1941631",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d50a1941631",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052779",
        "messages": [
          {
            "id": "17593d524d00832a",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d524d00832a",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052787",
        "messages": [
          {
            "id": "17593d543aca7123",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d543aca7123",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052795",
        "messages": [
          {
            "id": "17593d58c935e600",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d58c935e600",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052803",
        "messages": [
          {
            "id": "17593d5bb5c85b6a",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d5bb5c85b6a",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052811",
        "messages": [
          {
            "id": "17593d5dbcbdb483",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d5dbcbdb483",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052819",
        "messages": [
          {
            "id": "17593d6456524a3e",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d6456524a3e",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052827",
        "messages": [
          {
            "id": "17593d651c36b3d1",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d651c36b3d1",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052832",
        "messages": [
          {
            "id": "17593d68a483b60b",
            "threadId": "17593ccb985185be"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d68a483b60b",
              "threadId": "17593ccb985185be",
              "labelIds": [
                "UNREAD",
                "IMPORTANT",
                "CATEGORY_PERSONAL",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9052883",
        "messages": [
          {
            "id": "17593d6999c086fb",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d6999c086fb",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052903",
        "messages": [
          {
            "id": "17593d6a894d936e",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d6a894d936e",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "SENT"
              ]
            }
          }
        ]
      },
      {
        "id": "9052985",
        "messages": [
          {
            "id": "17593d8be20c7210",
            "threadId": "17593ccb985185be"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593d8be20c7210",
              "threadId": "17593ccb985185be",
              "labelIds": [
                "UNREAD",
                "IMPORTANT",
                "CATEGORY_PERSONAL",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9053039",
        "messages": [
          {
            "id": "17593da762dd6b35",
            "threadId": "17593ccb985185be"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593da762dd6b35",
              "threadId": "17593ccb985185be",
              "labelIds": [
                "UNREAD",
                "IMPORTANT",
                "CATEGORY_PERSONAL",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9053083",
        "messages": [
          {
            "id": "17593e16dda506dd",
            "threadId": "17593ccb985185be"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593e16dda506dd",
              "threadId": "17593ccb985185be",
              "labelIds": [
                "UNREAD",
                "IMPORTANT",
                "CATEGORY_PERSONAL",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9053121",
        "messages": [
          {
            "id": "17593e5f87e7caab",
            "threadId": "17593ccb985185be"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593e5f87e7caab",
              "threadId": "17593ccb985185be",
              "labelIds": [
                "UNREAD",
                "IMPORTANT",
                "CATEGORY_PERSONAL",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9053544",
        "messages": [
          {
            "id": "17593fcb8d7fb0e6",
            "threadId": "17593fcb8d7fb0e6"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17593fcb8d7fb0e6",
              "threadId": "17593fcb8d7fb0e6",
              "labelIds": [
                "CATEGORY_PROMOTIONS",
                "UNREAD",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9053712",
        "messages": [
          {
            "id": "1759400bd1297856",
            "threadId": "1759400bd1297856"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759400bd1297856",
              "threadId": "1759400bd1297856",
              "labelIds": [
                "UNREAD",
                "IMPORTANT",
                "CATEGORY_UPDATES",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9053948",
        "messages": [
          {
            "id": "175941893bf75154",
            "threadId": "175941893bf75154"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175941893bf75154",
              "threadId": "175941893bf75154",
              "labelIds": [
                "CATEGORY_PROMOTIONS",
                "UNREAD"
              ]
            }
          }
        ]
      },
      {
        "id": "9054011",
        "messages": [
          {
            "id": "17594376b0a512a9",
            "threadId": "174df8b54ee4e2da"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17594376b0a512a9",
              "threadId": "174df8b54ee4e2da",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054023",
        "messages": [
          {
            "id": "17594379dedd7954",
            "threadId": "174df8b54ee4e2da"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17594379dedd7954",
              "threadId": "174df8b54ee4e2da",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054032",
        "messages": [
          {
            "id": "1759437cc52a06d3",
            "threadId": "174df8b54ee4e2da"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759437cc52a06d3",
              "threadId": "174df8b54ee4e2da",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054041",
        "messages": [
          {
            "id": "175943808dfb1083",
            "threadId": "174df8b54ee4e2da"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175943808dfb1083",
              "threadId": "174df8b54ee4e2da",
              "labelIds": [
                "SENT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054103",
        "messages": [
          {
            "id": "175943896ec63977",
            "threadId": "1757a5438f6a6b1b"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175943896ec63977",
              "threadId": "1757a5438f6a6b1b",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054115",
        "messages": [
          {
            "id": "1759438b2bf72242",
            "threadId": "1757a5438f6a6b1b"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759438b2bf72242",
              "threadId": "1757a5438f6a6b1b",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054124",
        "messages": [
          {
            "id": "1759438d68525843",
            "threadId": "1757a5438f6a6b1b"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759438d68525843",
              "threadId": "1757a5438f6a6b1b",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054133",
        "messages": [
          {
            "id": "1759438f631c8190",
            "threadId": "1757a5438f6a6b1b"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759438f631c8190",
              "threadId": "1757a5438f6a6b1b",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054142",
        "messages": [
          {
            "id": "175943b89f1b7797",
            "threadId": "1757a5438f6a6b1b"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175943b89f1b7797",
              "threadId": "1757a5438f6a6b1b",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054151",
        "messages": [
          {
            "id": "175943bc1c918615",
            "threadId": "1757a5438f6a6b1b"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175943bc1c918615",
              "threadId": "1757a5438f6a6b1b",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054160",
        "messages": [
          {
            "id": "175943bccd37077c",
            "threadId": "1757a5438f6a6b1b"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175943bccd37077c",
              "threadId": "1757a5438f6a6b1b",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054169",
        "messages": [
          {
            "id": "175943c090b57d16",
            "threadId": "1757a5438f6a6b1b"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175943c090b57d16",
              "threadId": "1757a5438f6a6b1b",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054178",
        "messages": [
          {
            "id": "175943c41757930e",
            "threadId": "1757a5438f6a6b1b"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175943c41757930e",
              "threadId": "1757a5438f6a6b1b",
              "labelIds": [
                "SENT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054355",
        "messages": [
          {
            "id": "1759443606b27129",
            "threadId": "17570c0c2abba776"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759443606b27129",
              "threadId": "17570c0c2abba776",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054367",
        "messages": [
          {
            "id": "175944385a1a2e36",
            "threadId": "17570c0c2abba776"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944385a1a2e36",
              "threadId": "17570c0c2abba776",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054376",
        "messages": [
          {
            "id": "17594447a1ef8e84",
            "threadId": "17570c0c2abba776"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17594447a1ef8e84",
              "threadId": "17570c0c2abba776",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054385",
        "messages": [
          {
            "id": "1759444bf331b514",
            "threadId": "17570c0c2abba776"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759444bf331b514",
              "threadId": "17570c0c2abba776",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054394",
        "messages": [
          {
            "id": "175944549c1ddb27",
            "threadId": "17570c0c2abba776"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944549c1ddb27",
              "threadId": "17570c0c2abba776",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054403",
        "messages": [
          {
            "id": "17594457c570526c",
            "threadId": "17570c0c2abba776"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17594457c570526c",
              "threadId": "17570c0c2abba776",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054415",
        "messages": [
          {
            "id": "1759445bdd5657e5",
            "threadId": "17570c0c2abba776"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759445bdd5657e5",
              "threadId": "17570c0c2abba776",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054424",
        "messages": [
          {
            "id": "1759445ce084bfb6",
            "threadId": "17570c0c2abba776"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759445ce084bfb6",
              "threadId": "17570c0c2abba776",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054433",
        "messages": [
          {
            "id": "175944618d10047b",
            "threadId": "17570c0c2abba776"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944618d10047b",
              "threadId": "17570c0c2abba776",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054442",
        "messages": [
          {
            "id": "175944673156fc57",
            "threadId": "17570c0c2abba776"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944673156fc57",
              "threadId": "17570c0c2abba776",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054451",
        "messages": [
          {
            "id": "17594467a61936fd",
            "threadId": "17570c0c2abba776"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17594467a61936fd",
              "threadId": "17570c0c2abba776",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054460",
        "messages": [
          {
            "id": "1759446861338dec",
            "threadId": "17570c0c2abba776"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759446861338dec",
              "threadId": "17570c0c2abba776",
              "labelIds": [
                "SENT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054542",
        "messages": [
          {
            "id": "17594482b5afc719",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17594482b5afc719",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054554",
        "messages": [
          {
            "id": "1759448c25e068e0",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759448c25e068e0",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054563",
        "messages": [
          {
            "id": "1759448d0e0d524d",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759448d0e0d524d",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054572",
        "messages": [
          {
            "id": "175944a0484efa7a",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944a0484efa7a",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054580",
        "messages": [
          {
            "id": "175944a71a493a5e",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944a71a493a5e",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054589",
        "messages": [
          {
            "id": "175944aa07bb550b",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944aa07bb550b",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054598",
        "messages": [
          {
            "id": "175944ae5230d6ca",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944ae5230d6ca",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054607",
        "messages": [
          {
            "id": "175944b219df300b",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944b219df300b",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054616",
        "messages": [
          {
            "id": "175944b6ee41a2f1",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944b6ee41a2f1",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054625",
        "messages": [
          {
            "id": "175944b8b1b14ad9",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944b8b1b14ad9",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054634",
        "messages": [
          {
            "id": "175944c494dbd797",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944c494dbd797",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054643",
        "messages": [
          {
            "id": "175944c57a286efc",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944c57a286efc",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054652",
        "messages": [
          {
            "id": "175944d7937e5b70",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944d7937e5b70",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054661",
        "messages": [
          {
            "id": "175944db1782f1b5",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944db1782f1b5",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054670",
        "messages": [
          {
            "id": "175944e0b81d0c66",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944e0b81d0c66",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054679",
        "messages": [
          {
            "id": "175944e23f2471f2",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944e23f2471f2",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054688",
        "messages": [
          {
            "id": "175944f6a085718f",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944f6a085718f",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054697",
        "messages": [
          {
            "id": "175944fba3aa6892",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175944fba3aa6892",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054706",
        "messages": [
          {
            "id": "17594518692d8ddd",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17594518692d8ddd",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054715",
        "messages": [
          {
            "id": "1759451a9c234bfb",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759451a9c234bfb",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054724",
        "messages": [
          {
            "id": "1759451baad90508",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759451baad90508",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "DRAFT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054733",
        "messages": [
          {
            "id": "1759452131670d31",
            "threadId": "17575e6093ed043e"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759452131670d31",
              "threadId": "17575e6093ed043e",
              "labelIds": [
                "SENT"
              ]
            }
          }
        ]
      },
      {
        "id": "9054794",
        "messages": [
          {
            "id": "1759457da3a7a593",
            "threadId": "1759457da3a7a593"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759457da3a7a593",
              "threadId": "1759457da3a7a593",
              "labelIds": [
                "UNREAD",
                "IMPORTANT",
                "CATEGORY_PERSONAL",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9054865",
        "messages": [
          {
            "id": "175945f9a93d59e6",
            "threadId": "175945f9a93d59e6"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175945f9a93d59e6",
              "threadId": "175945f9a93d59e6",
              "labelIds": [
                "UNREAD",
                "CATEGORY_UPDATES",
                "SPAM"
              ]
            }
          }
        ]
      },
      {
        "id": "9054882",
        "messages": [
          {
            "id": "1759462ec11bb446",
            "threadId": "1758aaf0c3f114ce"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759462ec11bb446",
              "threadId": "1758aaf0c3f114ce",
              "labelIds": [
                "UNREAD",
                "IMPORTANT",
                "CATEGORY_PERSONAL",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9054936",
        "messages": [
          {
            "id": "175946379fc15a84",
            "threadId": "175946379fc15a84"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175946379fc15a84",
              "threadId": "175946379fc15a84",
              "labelIds": [
                "UNREAD",
                "CATEGORY_PERSONAL",
                "SPAM"
              ]
            }
          }
        ]
      },
      {
        "id": "9054955",
        "messages": [
          {
            "id": "175946b79c398540",
            "threadId": "175946b79c398540"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175946b79c398540",
              "threadId": "175946b79c398540",
              "labelIds": [
                "CATEGORY_PROMOTIONS",
                "UNREAD"
              ]
            }
          }
        ]
      },
      {
        "id": "9055008",
        "messages": [
          {
            "id": "175946e9ebc54b3f",
            "threadId": "17593d2cf8b3e348"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "175946e9ebc54b3f",
              "threadId": "17593d2cf8b3e348",
              "labelIds": [
                "UNREAD",
                "IMPORTANT",
                "CATEGORY_PERSONAL",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9055062",
        "messages": [
          {
            "id": "17594891a2ef2a6f",
            "threadId": "17594891a2ef2a6f"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17594891a2ef2a6f",
              "threadId": "17594891a2ef2a6f",
              "labelIds": [
                "UNREAD",
                "IMPORTANT",
                "CATEGORY_PERSONAL",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9055139",
        "messages": [
          {
            "id": "17594bd4fa4ba061",
            "threadId": "17594bd4fa4ba061"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17594bd4fa4ba061",
              "threadId": "17594bd4fa4ba061",
              "labelIds": [
                "CATEGORY_PROMOTIONS",
                "UNREAD"
              ]
            }
          }
        ]
      },
      {
        "id": "9055187",
        "messages": [
          {
            "id": "17594c160e3cd082",
            "threadId": "17594c160e3cd082"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "17594c160e3cd082",
              "threadId": "17594c160e3cd082",
              "labelIds": [
                "UNREAD",
                "IMPORTANT",
                "CATEGORY_FORUMS",
                "SENT",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9055327",
        "messages": [
          {
            "id": "1759515313b879de",
            "threadId": "1759515313b879de"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759515313b879de",
              "threadId": "1759515313b879de",
              "labelIds": [
                "CATEGORY_PROMOTIONS",
                "UNREAD",
                "INBOX"
              ]
            }
          }
        ]
      },
      {
        "id": "9055390",
        "messages": [
          {
            "id": "1759515470904ade",
            "threadId": "1759515313b879de"
          }
        ],
        "messagesAdded": [
          {
            "message": {
              "id": "1759515470904ade",
              "threadId": "1759515313b879de",
              "labelIds": [
                "CATEGORY_PROMOTIONS",
                "UNREAD",
                "INBOX"
              ]
            }
          }
        ]
      }
    ],
    "nextPageToken": "16766451912534182991",
    "historyId": "9063342"
  }


  ### sample message payload:
  {
    "id": "17593c41e72cbe31",
    "threadId": "17593c41e72cbe31",
    "labelIds": [
      "UNREAD",
      "IMPORTANT",
      "TRASH",
      "CATEGORY_PERSONAL",
      "SENT"
    ],
    "snippet": "A new filter build event has been created by Chip Kragt. Use the link below to add this event to your Google calendar. Use the attached iCal for other calendar types. Here are the details: Sun, 11/15 1",
    "payload": {
      "partId": "",
      "mimeType": "multipart/mixed",
      "filename": "",
      "headers": [
        {
          "name": "Delivered-To",
          "value": "chip@20liters.org"
        },
        {
          "name": "Received",
          "value": "by 2002:a5e:c80c:0:0:0:0:0 with SMTP id y12csp4232242iol;        Wed, 4 Nov 2020 06:58:25 -0800 (PST)"
        },
        {
          "name": "X-Google-Smtp-Source",
          "value": "ABdhPJxPXHHYgtU0DFsmp+PBa5S1jRmzF1yVAhk/n3Y45sytSqovAJQ99rMmUH9rfX/x1N4cND9I"
        },
        {
          "name": "X-Received",
          "value": "by 2002:a92:9119:: with SMTP id t25mr17968927ild.90.1604501905276;        Wed, 04 Nov 2020 06:58:25 -0800 (PST)"
        },
        {
          "name": "ARC-Seal",
          "value": "i=1; a=rsa-sha256; t=1604501905; cv=none;        d=google.com; s=arc-20160816;        b=DVJEeIBKwc5qzfwrFM+mFm7yZxniBhJyv0Vj15J25zvIVcmBhSyNTwTqfqKSurC9J2         JBwkpaESNUFWjykhu73LFadAvh6qsk39OHpRxVCkfT7ZQypqHZd3p6EVNrydRfMru7A1         TnqFMZ+x4eyceRHC0Npgbp6Dq+n6Ujncm+1YRbqERhkvvaSaNhMVvQsYA1V2GqJSMiOs         clYJLy8DnUMyDrCegtMIcda3DBc4rprZ5bp1elzR0Tje+NtOTF5PnsNLCNwuN0XjNZ9z         1TOMAqatMMVAZaGBW+d++cvoXhELcNzC9DW5AnCqeiGaGzS4+bT2GRm2pkOVRgWM21Ts         DXuQ=="
        },
        {
          "name": "ARC-Message-Signature",
          "value": "i=1; a=rsa-sha256; c=relaxed/relaxed; d=google.com; s=arc-20160816;        h=content-transfer-encoding:mime-version:subject:message-id:to:from         :date:sender:dkim-signature;        bh=+YUXsyPzq8rj7eK7JxOLbvSZOswGCOOGHHOFYVnI+FQ=;        b=AY22LUja9cL0gjKYCOaFC9+cQiShEHWnQ7W4lBMDKPLXNXCcQpNs0V+TvhB1oDXt2g         SSi1oAivG3Y0+LsQdsV8d6MIcKJ40ZoaHZDoYj8l1Rg8s1Cgh5JHRmyaf1lHtCdW+qip         PrXkSOTEqYK9cwzGjyV8fM7RXfUmm3qlwqf72/Z74m+wrbtHSu8XZ8cLL6/vbJp4zfLV         C0sm4RY0BWAyBp1cgwrTJfv2w6DYQtgT7IvPHxiYW84BuRnzQYoPt5rLS05zWTtFeGeD         8NQKACjB8SGvtLKtyCrbHkEwtRkJ5TUIni2eTt4ZvHdHLonxh/fW3xzi9HeY31cw4x8j         tbmw=="
        },
        {
          "name": "ARC-Authentication-Results",
          "value": "i=1; mx.google.com;       dkim=pass header.i=@mg.20liters.org header.s=pic header.b=E4GsNBHh;       spf=pass (google.com: domain of bounce+86d94b.7440b5-chip=20liters.org@mg.20liters.org designates 198.61.254.16 as permitted sender) smtp.mailfrom=\"bounce+86d94b.7440b5-chip=20liters.org@mg.20liters.org\";       dmarc=pass (p=NONE sp=NONE dis=NONE) header.from=20liters.org"
        },
        {
          "name": "Return-Path",
          "value": "\u003cbounce+86d94b.7440b5-chip=20liters.org@mg.20liters.org\u003e"
        },
        {
          "name": "Received",
          "value": "from so254-16.mailgun.net (so254-16.mailgun.net. [198.61.254.16])        by mx.google.com with UTF8SMTPS id l73si1168432ild.89.2020.11.04.06.58.24        for \u003cchip@20liters.org\u003e        (version=TLS1_3 cipher=TLS_AES_128_GCM_SHA256 bits=128/128);        Wed, 04 Nov 2020 06:58:25 -0800 (PST)"
        },
        {
          "name": "Received-SPF",
          "value": "pass (google.com: domain of bounce+86d94b.7440b5-chip=20liters.org@mg.20liters.org designates 198.61.254.16 as permitted sender) client-ip=198.61.254.16;"
        },
        {
          "name": "Authentication-Results",
          "value": "mx.google.com;       dkim=pass header.i=@mg.20liters.org header.s=pic header.b=E4GsNBHh;       spf=pass (google.com: domain of bounce+86d94b.7440b5-chip=20liters.org@mg.20liters.org designates 198.61.254.16 as permitted sender) smtp.mailfrom=\"bounce+86d94b.7440b5-chip=20liters.org@mg.20liters.org\";       dmarc=pass (p=NONE sp=NONE dis=NONE) header.from=20liters.org"
        },
        {
          "name": "DKIM-Signature",
          "value": "a=rsa-sha256; v=1; c=relaxed/relaxed; d=mg.20liters.org; q=dns/txt; s=pic; t=1604501905; h=Content-Transfer-Encoding: Content-Type: Mime-Version: Subject: Message-ID: To: From: Date: Sender; bh=+YUXsyPzq8rj7eK7JxOLbvSZOswGCOOGHHOFYVnI+FQ=; b=E4GsNBHhkM49B9fSggv3Z7F1TJ8VrTVW0UHXBN4fsXzvK+NS3knsXL+jseK7Vb4BOwBMVQOx 0n3tbo9Ey3loDVKt7XWl/6ON8Zk7m8HdJYAFC/l57PvUyuJrqiXJbdrJeFlwjDxg/Op6Cymf ozFh5g0xkFOOOI8qPb+wamRqraQ="
        },
        {
          "name": "X-Mailgun-Sending-Ip",
          "value": "198.61.254.16"
        },
        {
          "name": "X-Mailgun-Sid",
          "value": "WyI5YmQxNCIsICJjaGlwQDIwbGl0ZXJzLm9yZyIsICI3NDQwYjUiXQ=="
        },
        {
          "name": "Received",
          "value": "from mg.20liters.org (ec2-34-227-206-49.compute-1.amazonaws.com [34.227.206.49]) by smtp-out-n01.prod.us-east-1.postgun.com with SMTP id 5fa2c161a6bf6cdf631b64c6 (version=TLS1.3, cipher=TLS_AES_128_GCM_SHA256); Wed, 04 Nov 2020 14:57:37 GMT"
        },
        {
          "name": "Sender",
          "value": "filterbuilds=20liters.org@mg.20liters.org"
        },
        {
          "name": "Date",
          "value": "Wed, 04 Nov 2020 14:57:36 +0000"
        },
        {
          "name": "From",
          "value": "filterbuilds@20liters.org"
        },
        {
          "name": "To",
          "value": "chip@20liters.org, amanda@20liters.org"
        },
        {
          "name": "Message-ID",
          "value": "\u003c5fa2c160bc7a5_42ad04ec7a5bc64753@892457f7-7ed1-4aa0-b82a-f7a9240119e9.mail\u003e"
        },
        {
          "name": "Subject",
          "value": "[20 Liters] New Filter Build Scheduled"
        },
        {
          "name": "Mime-Version",
          "value": "1.0"
        },
        {
          "name": "Content-Type",
          "value": "multipart/mixed; boundary=\"--==_mimepart_5fa2c160bbdc2_42ad04ec7a5bc646b3\"; charset=UTF-8"
        },
        {
          "name": "Content-Transfer-Encoding",
          "value": "7bit"
        }
      ],
      "body": {
        "size": 0
      },
      "parts": [
        {
          "partId": "0",
          "mimeType": "text/html",
          "filename": "",
          "headers": [
            {
              "name": "Content-Type",
              "value": "text/html; charset=UTF-8"
            },
            {
              "name": "Content-Transfer-Encoding",
              "value": "7bit"
            }
          ],
          "body": {
            "size": 4370,
            "data": "PCFET0NUWVBFIGh0bWw-DQo8aHRtbCBzdHlsZT0iZm9udC1mYW1pbHk6ICdIZWx2ZXRpY2EgTmV1ZScsIEhlbHZldGljYSwgQXJpYWwsIHNhbnMtc2VyaWY7IC1tcy10ZXh0LXNpemUtYWRqdXN0OiAxMDAlOyAtd2Via2l0LXRleHQtc2l6ZS1hZGp1c3Q6IDEwMCU7IGZvbnQtc2l6ZTogMTBweDsgLXdlYmtpdC10YXAtaGlnaGxpZ2h0LWNvbG9yOiByZ2JhKDAsIDAsIDAsIDApOyBtYXJnaW46IDA7IGZvbnQtc2l6ZTogMTRweDsgbGluZS1oZWlnaHQ6IDEuNDI4NTcxNDM7IGNvbG9yOiAjMzMzMzMzOyBiYWNrZ3JvdW5kLWNvbG9yOiAjZmZmZmZmOyI-DQogIDxoZWFkPg0KICAgIDxtZXRhIGh0dHAtZXF1aXY9IkNvbnRlbnQtVHlwZSIgY29udGVudD0idGV4dC9odG1sOyBjaGFyc2V0PXV0Zi04IiAvPg0KICA8L2hlYWQ-DQogIDxib2R5Pg0KICAgIDxkaXYgY2xhc3M9ImNvbnRhaW5lciIgc3R5bGU9Im1hcmdpbi1yaWdodDogYXV0bzsgbWFyZ2luLWxlZnQ6IGF1dG87IHBhZGRpbmctbGVmdDogMTVweDsgcGFkZGluZy1yaWdodDogMTVweDsiPg0KICAgICAgPGRpdiBjbGFzcz0icm93IiBzdHlsZT0ibWFyZ2luLWxlZnQ6IC0xNXB4OyBtYXJnaW4tcmlnaHQ6IC0xNXB4OyI-DQogICAgICAgIDxkaXYgY2xhc3M9Indob2xlIiBzdHlsZT0icG9zaXRpb246IHJlbGF0aXZlOyBtaW4taGVpZ2h0OiAxcHg7IHBhZGRpbmctbGVmdDogMTVweDsgcGFkZGluZy1yaWdodDogMTVweDsgZmxvYXQ6IGxlZnQ7IHdpZHRoOiAxMDAlOyI-DQogIDxoMj5BIG5ldyBmaWx0ZXIgYnVpbGQgZXZlbnQgaGFzIGJlZW4gY3JlYXRlZCBieSBDaGlwIEtyYWd0LjwvaDI-DQogIDxwPlVzZSB0aGUgbGluayBiZWxvdyB0byBhZGQgdGhpcyBldmVudCB0byB5b3VyIEdvb2dsZSBjYWxlbmRhci48L3A-DQogIDxwPlVzZSB0aGUgYXR0YWNoZWQgaUNhbCBmb3Igb3RoZXIgY2FsZW5kYXIgdHlwZXMuPC9wPg0KPC9kaXY-DQoNCjxkaXYgY2xhc3M9Indob2xlIiBzdHlsZT0icG9zaXRpb246IHJlbGF0aXZlOyBtaW4taGVpZ2h0OiAxcHg7IHBhZGRpbmctbGVmdDogMTVweDsgcGFkZGluZy1yaWdodDogMTVweDsgZmxvYXQ6IGxlZnQ7IHdpZHRoOiAxMDAlOyI-DQogIDxwIHN0eWxlPSJtYXJnaW4tYm90dG9tOiA2cHgiPjxzdHJvbmc-SGVyZSBhcmUgdGhlIGRldGFpbHM6PC9zdHJvbmc-PC9wPg0KICA8ZGl2IGNsYXNzPSJ3aG9sZSIgc3R5bGU9InBvc2l0aW9uOiByZWxhdGl2ZTsgbWluLWhlaWdodDogMXB4O2Zsb2F0OiBsZWZ0OyB3aWR0aDogMTAwJTsiPg0KICA8aDMgc3R5bGU9Im1hcmdpbi1ib3R0b206IDZweDsiPlN1biwgMTEvMTUgMTowMHBtIC0gMzowMHBtPC9oMz4NCiAgPGg0IHN0eWxlPSJtYXJnaW46IDZweCBhdXRvOyI-SHVnZ2V0dCBGYW1pbHkgRmlsdGVyIEJ1aWxkPC9oND4NCiAgPHA-DQogICAgPHN0cm9uZz5Mb2NhdGlvbjo8L3N0cm9uZz4gPGJyPg0KICAgIDIwIExpdGVycyA8YnI-DQogICAgMjkwMCBXaWxzb24gQXZlIFNXIDxicj4NCiAgICAgIFN1aXRlICMgMTEwIDxicj4NCiAgICBHcmFuZHZpbGxlLCBNSSAgNDk0MTgNCiAgPC9wPg0KDQogICAgPGEgY2xhc3M9ImJ0biB5ZWxsb3cgZmlsbGVkIiB0YXJnZXQ9Il9ibGFuayIgc3R5bGU9ImRpc3BsYXk6IGlubGluZS1ibG9jazsgbWFyZ2luLWJvdHRvbTogMDsgZm9udC13ZWlnaHQ6IG5vcm1hbDsgdGV4dC1hbGlnbjogY2VudGVyOyB2ZXJ0aWNhbC1hbGlnbjogbWlkZGxlOyBib3JkZXI6IDFweCBzb2xpZCB0cmFuc3BhcmVudDsgd2hpdGUtc3BhY2U6IG5vd3JhcDsgcGFkZGluZzogNnB4IDEycHg7IGZvbnQtc2l6ZTogMTRweDsgdGV4dC1kZWNvcmF0aW9uOiBub25lOyBjb2xvcjogIzRhNGE0YTsgYmFja2dyb3VuZC1jb2xvcjogI2ZjZTAwMDsgYm9yZGVyLWNvbG9yOiAjI2ZjYzkwMDsiIGhyZWY9Imh0dHBzOi8vZ29vLmdsL21hcHMvMmR5VTFyM0xpbUtFUW56eTkiPk1hcDwvYT4NCiAgICA8YSBjbGFzcz0iYnRuIHllbGxvdyBmaWxsZWQiIHRhcmdldD0iX2JsYW5rIiBzdHlsZT0iZGlzcGxheTogaW5saW5lLWJsb2NrOyBtYXJnaW4tYm90dG9tOiAwOyBmb250LXdlaWdodDogbm9ybWFsOyB0ZXh0LWFsaWduOiBjZW50ZXI7IHZlcnRpY2FsLWFsaWduOiBtaWRkbGU7IGJvcmRlcjogMXB4IHNvbGlkIHRyYW5zcGFyZW50OyB3aGl0ZS1zcGFjZTogbm93cmFwOyBwYWRkaW5nOiA2cHggMTJweDsgZm9udC1zaXplOiAxNHB4OyB0ZXh0LWRlY29yYXRpb246IG5vbmU7IGNvbG9yOiAjNGE0YTRhOyBiYWNrZ3JvdW5kLWNvbG9yOiAjZmNlMDAwOyBib3JkZXItY29sb3I6ICMjZmNjOTAwOyIgaHJlZj0iaHR0cHM6Ly8yMGxpdGVycy5vcmcvd3AtY29udGVudC91cGxvYWRzLzIwMjAvMDEvMjBMX2xvY2F0aW9uX2ZpbHRlcmJ1aWxkcy5wbmciPlBob3RvPC9hPg0KPC9kaXY-DQo8ZGl2IGNsYXNzPSJ3aG9sZSIgc3R5bGU9InBvc2l0aW9uOiByZWxhdGl2ZTsgbWluLWhlaWdodDogMXB4OyBmbG9hdDogbGVmdDsgd2lkdGg6IDEwMCU7Ij4NCjwvZGl2Pg0KDQo8L2Rpdj4NCjxkaXYgY2xhc3M9InJvdyIgc3R5bGU9Im1hcmdpbi10b3A6IDI2cHg7IG1hcmdpbi1sZWZ0OiAtMTVweDsgbWFyZ2luLXJpZ2h0OiAtMTVweDsgIj4NCiAgPGRpdiBjbGFzcz0id2hvbGUiIHN0eWxlPSJwb3NpdGlvbjogcmVsYXRpdmU7IG1pbi1oZWlnaHQ6IDFweDsgcGFkZGluZy1sZWZ0OiAxNXB4OyBwYWRkaW5nLXJpZ2h0OiAxNXB4OyBmbG9hdDogbGVmdDsgd2lkdGg6IDUwJTsgdGV4dC1hbGlnbjogY2VudGVyOyI-DQogICAgPGEgY2xhc3M9ImJ0biB5ZWxsb3ciIHRhcmdldD0iX2JsYW5rIiBzdHlsZT0iZGlzcGxheTogaW5saW5lLWJsb2NrOyBtYXJnaW4tYm90dG9tOiAwOyBmb250LXdlaWdodDogbm9ybWFsOyB0ZXh0LWFsaWduOiBjZW50ZXI7IHZlcnRpY2FsLWFsaWduOiBtaWRkbGU7IGJvcmRlcjogMXB4IHNvbGlkIHRyYW5zcGFyZW50OyB3aGl0ZS1zcGFjZTogbm93cmFwOyBwYWRkaW5nOiA2cHggMTJweDsgZm9udC1zaXplOiAxNHB4OyB0ZXh0LWRlY29yYXRpb246IG5vbmU7IGNvbG9yOiAjNGE0YTRhOyBiYWNrZ3JvdW5kLWNvbG9yOiAjZmNlMDAwOyBib3JkZXItY29sb3I6ICMjZmNjOTAwOyIgaHJlZj0iaHR0cHM6Ly93d3cuZ29vZ2xlLmNvbS9jYWxlbmRhci9ldmVudD9hY3Rpb249VEVNUExBVEUmYW1wO3RleHQ9SHVnZ2V0dCUyMEZhbWlseSUyMEZpbHRlciUyMEJ1aWxkOiUyMEhvdXNlaG9sZCUyMEZpbHRlciZhbXA7ZGF0ZXM9MjAyMDExMTVUMTgwMDAwWi8yMDIwMTExNVQyMDAwMDBaJmFtcDtkZXRhaWxzPVByaXZhdGUlMjBFdmVudCZhbXA7bG9jYXRpb249MjkwMCUyMFdpbHNvbiUyMEF2ZSUyMFNXLCUyMEdyYW5kdmlsbGUsJTIwTUklMjA0OTQxOCZhbXA7dHJwPWZhbHNlJmFtcDtzcHJvcD1odHRwczovYnVpbGQudmlsbGFnZXdhdGVyZmlsdGVycy5vcmcvJmFtcDtzcHJvcD1uYW1lOjIwJTIwTGl0ZXJzIj5BZGQgdG8gbXkgR29vZ2xlIENhbGVuZGFyPC9hPg0KICA8L2Rpdj4NCiAgPGRpdiBjbGFzcz0id2hvbGUiIHN0eWxlPSJwb3NpdGlvbjogcmVsYXRpdmU7IG1pbi1oZWlnaHQ6IDFweDsgcGFkZGluZy1sZWZ0OiAxNXB4OyBwYWRkaW5nLXJpZ2h0OiAxNXB4OyBmbG9hdDogbGVmdDsgd2lkdGg6IDIwJTsgdGV4dC1hbGlnbjogY2VudGVyOyI-DQogICAgPGEgY2xhc3M9ImJ0biBibHVlIiB0YXJnZXQ9Il9ibGFuayIgc3R5bGU9ImRpc3BsYXk6IGlubGluZS1ibG9jazsgbWFyZ2luLWJvdHRvbTogMDsgZm9udC13ZWlnaHQ6IG5vcm1hbDsgdGV4dC1hbGlnbjogY2VudGVyOyB2ZXJ0aWNhbC1hbGlnbjogbWlkZGxlOyBib3JkZXI6IDFweCBzb2xpZCB0cmFuc3BhcmVudDsgd2hpdGUtc3BhY2U6IG5vd3JhcDsgcGFkZGluZzogNnB4IDEycHg7IGZvbnQtc2l6ZTogMTRweDsgdGV4dC1kZWNvcmF0aW9uOiBub25lOyBjb2xvcjogIzRhNGE0YTsgYmFja2dyb3VuZC1jb2xvcjogIzliYjRjODsgYm9yZGVyLWNvbG9yOiAjOTFhMGM4OyIgaHJlZj0iaHR0cHM6Ly9tYWtlLjIwbGl0ZXJzLm9yZyI-R28gdG8gbWFrZS4yMGxpdGVycy5vcmc8L2E-DQogIDwvZGl2Pg0KPC9kaXY-DQoNCg0KDQoNCiAgICAgICAgPGRpdiBjbGFzcz0id2hvbGUiIHN0eWxlPSJwb3NpdGlvbjogcmVsYXRpdmU7IG1pbi1oZWlnaHQ6IDFweDsgcGFkZGluZy1sZWZ0OiAxNXB4OyBwYWRkaW5nLXJpZ2h0OiAxNXB4OyBmbG9hdDogbGVmdDsgd2lkdGg6IDEwMCU7Ij4NCiAgICAgICAgICA8cCBzdHlsZT0ibWFyZ2luLWJvdHRvbTogM3B4OyI-VGhhbmtzITwvcD4NCiAgICAgICAgICA8cCBzdHlsZT0ibWFyZ2luLXRvcDogM3B4Ij48c3Ryb25nPi0gMjAgTGl0ZXJzPC9zdHJvbmc-PC9wPg0KICAgICAgICA8L2Rpdj4NCiAgICAgIDwvZGl2Pg0KICAgIDwvZGl2Pg0KICA8L2JvZHk-DQo8L2h0bWw-DQo="
          }
        },
        {
          "partId": "1",
          "mimeType": "text/calendar",
          "filename": "20Liters_filterbuild_20201115T1300.ical",
          "headers": [
            {
              "name": "Content-Type",
              "value": "text/calendar; charset=UTF-8"
            },
            {
              "name": "Content-Transfer-Encoding",
              "value": "base64"
            },
            {
              "name": "Content-Disposition",
              "value": "attachment; filename=20Liters_filterbuild_20201115T1300.ical"
            },
            {
              "name": "Content-ID",
              "value": "\u003c5fa2c160bd345_42ad04ec7a5bc64865@892457f7-7ed1-4aa0-b82a-f7a9240119e9.mail\u003e"
            }
          ],
          "body": {
            "attachmentId": "ANGjdJ8igy9lN9CL2fuGOZaYq8sP7NCygU-pnSukAkPjb0QwL6RRW6Rp2i7aeXlZmjDlM52_A1ugDwYJaOpg_oDmRcT_nJ3nGR4o7W2-kK9FGk_oK4_hkM95lDyEnmD04J8hDQ6F3uZs3xTqqo-MAvvU6zQ4Yi-zDeG_yevR05l7RJeKPhQELx-hint1tTKbcHGLNkyUl5xomFB5-ff-zpWsuo0NmOZn93NYH--QensjVbyQEnwKGQSNNX-eORakg9t1cwTzjE8mIiL6a1cXc9afeiqbw5VeSLpctPSD-oO3h8LVBX0sHyv2nSngeftwzYVSqYni4mL_Fw4Z-1-dyOxrkfcklTpjvHsfDHd3BFphFBmkfY-gpdo8dCnM6aFnALHFDfNoONFrKz5HMXir",
            "size": 495
          }
        }
      ]
    },
    "sizeEstimate": 9741,
    "historyId": "9051850",
    "internalDate": "1604501856000"
  }

  3. Google's Pub/Sub API can notify via webhook whenever a message is received
  --> https://developers.google.com/gmail/api/guides/push
  * user still Oauths into the service
  * then add a watch call via `watch_user()`: https://github.com/googleapis/google-api-ruby-client/blob/d652f7ae9b1fcd07395c3aa72306188c4b4bbd1a/generated/google/apis/gmail_v1/service.rb#L133
  * still need a cron job to call `watch_user()` once per day
=end
end
