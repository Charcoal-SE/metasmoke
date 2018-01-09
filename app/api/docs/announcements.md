# Announcements

---
/api/v2.0/announcements | List all announcements.

Available tables: `announcements`
Output format:

    {
        "items": [
            {
                "id": 25,
                "text": "Test API announcement",
                "expiry": "2017-12-13T19:00:00.000Z"
            }
        ],
        "has_more": true
    }

---
/api/v2.0/announcements/active | List active (non-expired) announcements.

Available tables: `announcements`
Output format: identical to `/announcements`.
---
/api/v2.0/announcements/expired | List expired announcements.

Available tables: `announcements`
Output format: identical to `/announcements`.
---
/api/v2.0/announcements/create | [W] Create an announcement.

Available tables: N/A. All fields are returned. Filter is ignored.  
Requires params: `text` and `expiry`. Requires core role.  
Output format:

    {
        "items": [
            {
                "id": 27,
                "text": "test from API",
                "expiry": "2017-01-01T00:00:00.000Z",
                "created_at": "2017-12-17T23:11:55.000Z",
                "updated_at": "2017-12-17T23:11:55.000Z"
            }
        ],
        "has_more": false
    }