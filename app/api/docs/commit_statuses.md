# Commit Statuses

---
/api/v2.0/commits | List all commit statuses.

Available tables: `commit_statuses`. Output format:

    {
        "items": [
            {
                "id": 3689,
                "commit_sha": "cb94d4592f0a0085302ad2dbed1b4aaa5db85d09",
                "status": "success"
            }
        ],
        "has_more": true
    }