# Posts

---
/api/v2.0/posts | List all posts.

Available tables: `posts`.
Output format:

    {
        "items": [
            {
                "id": 78099,
                "title": "test",
                "link": "//stackoverflow.com/a/3498236",
                "site_id": 1,
                "user_link": "//stackoverflow.com/u/3160466",
                "username": "ArtOfCode",
                "user_reputation": 3478
            }
        ],
        "has_more": true
    }
---
/api/v2.0/posts/between | List posts within a specified date range.

Requires params: `from` (range start date) and `to` (range end date). Both are in ISO 8601 format - `1970-01-01T00:00:00.000000Z`.
Available tables: `posts`.
Output format: identical to `/posts`.
---
/api/v2.0/posts/site | List posts on a specific site.

Requires params: `site` (site domain name).
Available tables: `posts`.
Output format: identical to `/posts`.
---
/api/v2.0/posts/urls | List posts specified by their URLs.

Requires params: `urls` (a **comma** separated list of URLs).
URLs are of the format //stackoverflow.com/a/12345 (for answers) or //stackoverflow.com/questions/12345 (for questions).
Available tables: `posts`.
Output format: identical to `/posts`.
---
/api/v2.0/posts/feedback | List posts by feedback types.

Requires params: `type` (feedback type).
Available tables: `posts`.
Output format: identical to `/posts`.
---
/api/v2.0/posts/undeleted | List posts that have not yet been deleted.

Looks for the absence of a DeletionLog record with `is_deleted: true` on the post - may not be 100% accurate; use the SE API if that's what you need.
Available tables: `posts`.
Output format: identical to `/posts`.
---
/api/v2.0/posts/:ids | List posts by their IDs

`ids` is a **comma** separated list of post IDs to return.
Available tables: `posts`.
Output format: identical to `/posts`.
---
/api/v2.0/posts/:id/reasons | List the reasons a post was caught by.

Available tables: `reasons`.
Output format:

    {
        "items": [
            {
                "id": 106,
                "reason_name": "Repeated url at end of long post",
                "weight": 99
            }
        ],
        "has_more": true
    }
---
/api/v2.0/posts/:id/domains | List the domain names contained in a post.

Available tables: `spam_domains`.
Output format:

    {
        "items": [
            {
                "id": 3993,
                "domain": "www.drhelpnutrition.org",
                "whois": null
            }
        ],
        "has_more": false
    }
---
/api/v2.0/posts/:id/flags | Get details of what automatic and manual flags have been cast on a post.

Available tables: N/A. This route provides a specific, unfilterable subset of information.
Output format:

    {
        "items": [
            {
                "id": 78000,
                "autoflagged": {
                    "flagged": true,
                    "users": [
                        {
                            "id": 14,
                            "username": "ProgramFOX",
                            "stackexchange_chat_id": 123456,
                            "stackoverflow_chat_id": 123456,
                            "meta_chat_id": 123456
                        },
                        {
                            "id": 42,
                            "username": "QPaysTaxes",
                            "stackexchange_chat_id": 123456,
                            "stackoverflow_chat_id": 123456,
                            "meta_chat_id": 123456
                        },
                        {
                            "id": 226,
                            "username": "guiniveretoo",
                            "stackexchange_chat_id": 123456,
                            "stackoverflow_chat_id": 123456,
                            "meta_chat_id": 123456
                        }
                    ]
                },
                "manual_flags": {
                    "users": [
                        {
                            "id": 7,
                            "username": "ArtOfCode",
                            "stackexchange_chat_id": 123456,
                            "stackoverflow_chat_id": 123456,
                            "meta_chat_id": 123456
                        }
                    ]
                }
            }
        ],
        "has_more": false
    }
---
/api/v2.0/posts/report | [W] Report a post.

**Write route**. Requires a POST request, valid write token, and parameters: `url` (the post URL to report).
Available tables: N/A. No database information is returned from this request.
All requests to this route will be met with a 202 Accepted status; metasmoke does not know the status of reports as it just forwards them to Smokey.
Output format:

    {
        "status": "Accepted"
    }
---
/api/v2.0/posts/:id/flag | [W] Cast a spam flag on a post.

**Write route**. Requires a POST request and valid write token.
Available tables: N/A. No database information is returned from this request.
`backoff` will only be set on successful requests. `message` will only be set on failed requests.
Output format:

    {
        "status": "success|failed",
        "backoff": "10",
        "message": "failure reason"
    }
---
/api/v2.0/posts/search{.:format} | Get an RSS or Atom feed of posts matching certain criteria.

`format` may be either `rss` or `atom`, e.g. `/api/v2.0/posts/search.rss`.
Filters are not available on this route.
Output format for RSS and Atom feeds is consistent with RSS and Atom standards, respectively.