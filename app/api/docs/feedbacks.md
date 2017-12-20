# Feedbacks

---
/api/v2.0/feedbacks | List all feedbacks

Available tables: `feedbacks`.
Output format:

    {
        "items": [
            {
                "id": 141289,
                "feedback_type": "fp-",
                "post_id": 78000,
                "user_id": 7
            }
        ],
        "has_more": true
    }
---
/api/v2.0/feedbacks/post/:id | List all feedbacks on the post specified.

Available tables: `feedbacks`.
Output format: identical to `/feedbacks`.
---
/api/v2.0/feedbacks/user/:id | List all feedbacks by the user specified.

Available tables: `feedbacks`.
Output format: identical to `/feedbacks`.
---
/api/v2.0/feedbacks/app/:id | List all feedbacks created by the app specified.

Available tables: `feedbacks`.
Output format: identical to `/feedbacks`.
---
/api/v2.0/feedbacks/post/:id/create | [W] Create a feedback on the post specified.

Available tables: `feedbacks`. Returns all feedbacks on the post.
**Write route**. Requires POST request, valid write token, and parameters: `type` (feedback type, i.e. `tpu-`).
Output format: identical to `/feedback`.