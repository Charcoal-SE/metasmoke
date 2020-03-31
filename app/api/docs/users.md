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
/api/v2.0/users/current | Get details of the current user

Available tables: `users`, `roles`.
Output format: Identical to /users.
