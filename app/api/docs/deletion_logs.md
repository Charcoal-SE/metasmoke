# Deletion logs

---
/api/v2.0/deletions | List all deletion logs.

Available tables: `deletion_logs`.
Output format:

    {
        "items": [
            {
                "id": 79044,
                "post_id": 78091,
                "is_deleted": true
            }
        ],
        "has_more": true
    }
---
/api/v2.0/deletions/post/:id | List deletion logs on the post specified.

Available tables: `deletion_logs`.
Output format: identical to `/deletions`.
---
/api/v2.0/deletions/post/:id | [W] Add a deletion log to a post.

**Write route.** Requires a POST request, trusted key, and valid write token.
Available tables: N/A. All fields on the created deletion log are returned.
Parameters: `is_deleted` (Boolean, required), `uncertainty` (Integer, seconds uncertainty, optional), `timestamp` (DateTime, deletion timestamp, optional)
Output format:

    {
        "items": [
            {
                "id": 106575,
                "post_id": 100000,
                "is_deleted": true,
                "created_at": "2021-01-01T00:00:00.000Z",
                "updated_at": "2018-02-15T21:12:02.000Z",
                "api_key_id": 1,
                "uncertainty": 0
            }
        ],
        "has_more": false
    }