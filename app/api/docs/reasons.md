# Reasons

---
/api/v2.0/reasons | List all reasons.

Available tables: `reasons`.
Output format:

    {
        "items": [
            {
                "id": 134,
                "reason_name": "Pattern-matching email in body",
                "weight": 0
            }
        ],
        "has_more": true
    }
---
/api/v2.0/reasons/:ids | List reasons specified by their IDs.

Available tables: `reasons`.
Output format: identical to `/reasons`.
---
/api/v2.0/reasons/:id/posts | List posts caught by a specific reason.

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