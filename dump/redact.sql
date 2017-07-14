UPDATE `api_tokens` SET `code` = '', `token` = '';
UPDATE `audits` SET `remote_address` = '';
TRUNCATE TABLE `flags`;
TRUNCATE TABLE `ignored_users`;
UPDATE `smoke_detectors` SET `access_token` = '';
UPDATE `users` SET
    `email` = CONCAT(`id`, "@metasmoke.fake"),
    `encrypted_password` = '',
    `reset_password_token` = '',
    `reset_password_sent_at` = NULL,
    `encrypted_api_token` = '',
    `two_factor_token` = NULL,
    `salt` = NULL,
    `iv` = NULL
