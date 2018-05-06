# Comments

---
/api/v2.0/comments | List all comments.

Available tables: `post_comments`.
Output format:

    {
        "items": [
            {
                "id": 2,
                "user_id": 1373,
                "text": "Some more words."
            }
        ],
        "has_more": true
    }
---
/api/v2.0/comments/post/:id | List all comments on a specified post.

Available tables: `post_comments`.
Output format: identical to `/comments`.
---
/api/v2.0/comments/post/:id | [W] [Smokey] Add an automatic comment to a post.

**This route is for use by SmokeDetector instances only.**
Requires parameters: `text`, `chat_user_id`, and `chat_host`.
Available tables: N/A. All fields on the created comment are returned.
Output format: identical to `/comments`.