# frozen_string_literal: true

module Websocket
  extend ActiveSupport::Concern

  included do
    after_create :broadcast_create
    after_update :broadcast_update

    def broadcast_event(type)
      event_class = self.class.to_s
      table = event_class.pluralize.underscore
      channel = "#{table}_#{type}"
      object_data = attributes.delete_if { |k, _| AppConfig['sensitive_fields'].include? "#{channel}.#{k}" }
      extended = respond_to?(:extended_websocket) ? extended_websocket : {}
      object_data.deep_merge! extended
      ApiChannel.broadcast_to channel, event_type: type, event_class: event_class, object: object_data
    end

    def broadcast_create
      broadcast_event 'create'
    end

    def broadcast_update
      broadcast_event 'update'
    end
  end
end
