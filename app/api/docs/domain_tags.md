# Tags

---
/api/v2.0/tags | List all tags.

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
---
/api/v2.0/tags/name/:name | List tags specified by their name.

Available tables: `domain_tags`.
Output format: identical to `/tags`.
---
/api/v2.0/tags/:id/domains | List the domains that a specific tag is used on.

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
        "has_more": false
    }