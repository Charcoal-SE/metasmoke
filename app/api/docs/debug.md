# Debug

---
/api/v2.0/debug | Return debugging information for the API. No key required.

No database queries are performed by this route; no tables are available.
Not really intended for API consumer use, more for API developers.
Output format:

    {
        "params": {
            "key": "abcdef012345",
            "per_page": "1"
        },
        "ts": "2017-12-18T00:46:14.812+00:00",
        "filters": {
            "announcements": "IJIHMOFFGGKIOKOGFJHMHHLOMIJFNGLLOHKMGIFKOMKLIILOGHLNNMJHJ",
            "apps": "MJMFOGKMLGMHGHFNGNJJOLOJGMKMIKMMKMHMFGJGIKIHHFLJKFLFLFN",
            "commits": "GFHIFKGGJLGIGLIHFJHMJHKMOINHOFGIONGGIMKOGKHMNFFNIH",
            "deletions": "MOOHKNMFMOGKIIMKIIIOHLJFGJHNOGMGMHMLIMJIINGFOJJ",
            "tags": "GHJNNJGMIGGGMMGJNOKOHLFFFHHIHLNIFNHJJIIJOFIHOL",
            "feedbacks": "HJKLKLLJLIHMKLINOKKJIJMOIOLKOMGJHGFMHGJIGKKH",
            "posts": "HKOMIKHOJJOHKLINJNOHMHMHKFGHJN",
            "reasons": "HOKGJMOFKGMOIKHNHKNKLFF",
            "smokeys": "ILMLMLLNNIHNHOJJ",
            "domains": "INJNHOFLOMHGL",
            "users": "JIKH"
        }
    }
---
/api/v2.0/debug/filter | Decode a filter back to a list of fields. No key required.

No database queries are performed by this route; no tables are available.
Pass a filter as the `filter` parameter to receive a list of fields the filter contains.
Output format:

    {
        "fields": [
            "posts.id",
            "posts.title",
            "posts.link",
            "posts.site_id",
            "posts.user_link",
            "posts.username",
            "posts.user_reputation"
        ]
    }