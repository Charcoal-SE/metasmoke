# frozen_string_literal: true

AppConfig = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]
