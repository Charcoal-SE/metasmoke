if File.readable?("REVISION")
  CurrentCommit = File.read("REVISION")
else
  CurrentCommit = nil
end
