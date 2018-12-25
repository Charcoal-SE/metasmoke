# frozen_string_literal: true

CurrentCommit = File.readable?('REVISION') ? File.read('REVISION').strip : `git rev-parse --short HEAD`.chomp # rubocop:disable Style/ConstantName
