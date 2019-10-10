DROP TABLE `ar_internal_metadata`;
TRUNCATE TABLE `api_tokens`;
UPDATE `api_keys` SET `key` = '';
UPDATE `audits` SET `remote_address` = '';
TRUNCATE TABLE `emails_preferences`;
TRUNCATE TABLE `emails_addressees`;
TRUNCATE TABLE `flags`;
UPDATE `smoke_detectors` SET `access_token` = '';
UPDATE `users` SET
    `email` = CONCAT(`id`, '@metasmoke.fake'),
    `encrypted_password` = '',
    `reset_password_token` = '',
    `reset_password_sent_at` = NULL,
    `encrypted_api_token_legacy` = '',
    `two_factor_token` = NULL,
    `enabled_2fa` = NULL,
    `salt` = NULL,
    `iv` = NULL;
