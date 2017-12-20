# Domains

---
/api/v2.0/domains | List all domains.

Available tables: `spam_domains`.
Output format:

    {
        "items": [
            {
                "id": 12935,
                "domain": "infinitemlmsoftware.com",
                "whois": null
            }
        ],
        "has_more": true
    }
---
/api/v2.0/domains/:id/posts | List all posts containing a specific domain.

Available tables: `posts`.
Output format:

    {
        "items": [
            {
                "id": 77988,
                "title": "Google Webmaster Tools show the error in Manual Action for my web - https://infinitemlmsoftware.com/",
                "link": "//drupal.stackexchange.com/questions/242498",
                "site_id": 86,
                "user_link": "https://drupal.stackexchange.com/users/77863/isha",
                "username": "isha",
                "user_reputation": 1
            }
        ],
        "has_more": false
    }
---
/api/v2.0/domains/:id/tags/add | [W] Add a tag to a specified domain.

**Write route**. Requires a POST request, valid write token, and params: `tag` (the name of the tag to add).
Available tables: `domain_tags`.
Output format:

    {
        "items": [
            {
                "id": 16,
                "name": "blargle",
                "description": null
            }
        ],
        "has_more": true
    }