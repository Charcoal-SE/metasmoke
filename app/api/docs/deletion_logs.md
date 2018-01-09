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