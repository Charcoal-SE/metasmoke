# SmokeDetectors

---
/api/v2.0/smokeys | List all SmokeDetector instances.

Available tables: `smoke_detectors`.
Output format:

    {
        "items": [
            {
                "id": 17,
                "last_ping": "2017-07-24T00:47:50.000Z",
                "location": "The Call of Midnight",
                "user_id": 47,
                "status_color": "critical"
            }
        ],
        "has_more": true
    }