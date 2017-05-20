CurrentCommit = (File.read('REVISION').strip if File.readable?('REVISION')) # rubocop:disable Style/ConstantName
