# frozen_string_literal: true

Travis.access_token = AppConfig['travis']['token'] if AppConfig['travis'].present? && AppConfig['travis']['token'].present?
