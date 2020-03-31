# Users

---
/api/v2.0/users | List all users.

Available tables: `users`.
Output format:

    {
        "items": [
            {
                "id": 311,
                "username": "Art"
            }
        ],
        "has_more": true
    }


---
/api/v2.0/users/with_role/:role | List all users with the specified role

Available tables: `users`.
Output format:

    {
        "items": [
            {
                "id": 311,
                "username": "Art"
            }
        ],
        "has_more": true
    }
---
/api/v2.0/users/current-roles | Get roles for the current user

Available tables: `roles`.
Output format:

    {
        "items": [
            {
                "id": 1,
                "name": "admin"
            }
        ],
        "has_more": false
    }
