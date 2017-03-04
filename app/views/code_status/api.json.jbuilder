json.repo @repo
json.compare @compare
json.compare_diff @compare_diff.encode("utf-8", :invalid => :replace, :undef => :replace, :replace => "?")
json.commit @commit
json.commit_diff @commit_diff.encode("utf-8", :invalid => :replace, :undef => :replace, :replace => "?")
json.commit_sha CurrentCommit
