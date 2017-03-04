json.repo @repo.to_h
json.compare @compare.to_h
json.compare_diff @compare_diff.encode("utf-8", :invalid => :replace, :undef => :replace, :replace => "?")
json.commit @commit.to_h
json.commit_diff @commit_diff.encode("utf-8", :invalid => :replace, :undef => :replace, :replace => "?")
json.commit_sha CurrentCommit
