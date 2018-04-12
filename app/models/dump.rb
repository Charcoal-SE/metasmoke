# frozen_string_literal: true

class Dump < ApplicationRecord
  has_attached_file :file,
                    storage: :s3,
                    bucket: 'erwaysoftware.metasmokedumps',
                    s3_credentials: proc { |a| a.instance.s3_credentials }

  do_not_validate_attachment_file_type :file

  def s3_credentials
    {
      bucket: 'erwaysoftware.metasmokedumps',
      access_key_id: AppConfig['aws']['access_token'],
      secret_access_key: AppConfig['aws']['secret_token']
    }
  end
end
