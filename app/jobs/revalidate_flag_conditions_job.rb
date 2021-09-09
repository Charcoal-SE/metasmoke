class RevalidateFlagConditionsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    FlagCondition.where(flags_enabled: true).find_each do |fc|
      unless fc.validate
        failures = fc.errors.full_messages
        fc.flags_enabled = false
        fc.save(validate: false)
        ActionCable.server.broadcast 'smokedetector_messages',
                                     message: "@#{fc.user&.username&.tr(' ', '')} " \
                                                "Your flag condition was disabled: #{failures.join(',')}"
      end
    end
  end
end
