if File.readable?('REVISION')
  CurrentCommit = File.read('REVISION').strip
else
  CurrentCommit = nil
end
