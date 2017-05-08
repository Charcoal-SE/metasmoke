module FlagSettingsHelper
  def flag_settings_plot_lines(start_time, end_time=Time.now)
    setting_ids = FlagSetting.where(name: ['max_flags', 'min_accuracy']).pluck(:id)

    audits = Audited::Audit.where(auditable_type: "FlagSetting")
             .where(action: "update")
             .where(auditable_id: setting_ids)
             .where(created_at: start_time..end_time)

    audits.map do |a|
      changes = a.audited_changes['value']
      {'width' => '1', value: a.created_at.to_i * 1000, color: 'lightgrey',
        label: { text: "#{FlagSetting.find(a.auditable_id).name.humanize}: #{changes.first} → #{changes.last}" },
        'zIndex' => 10 }
    end
  end
end
