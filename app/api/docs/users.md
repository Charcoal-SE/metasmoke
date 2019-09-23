# Users

---
/api/v2.0/users | List all users. No key required.

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
/api/v2.0/users/with_role/:role | List all users with the specified role. No key required.

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
