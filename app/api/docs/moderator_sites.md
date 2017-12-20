# Moderator Sites

---
/api/v2.0/mods | List all ModeratorSites.

Available tables: `moderator_sites`.
Output format:

    {
        "items": [
            {
                "id": 970,
                "user_id": 5,
                "site_id": 1
            }
        ],
        "has_more": true
    }
---
/api/v2.0/mods/user/:id | List all ModeratorSites for the specified user.

Available tables: `moderator_sites`.
Output format: identical to `/mods`.