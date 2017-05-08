# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

SmokeDetector.create(
  last_ping: 1.hour.ago,
  name: 'Seed',
  location: 'Nowhere',
  access_token: '9b104345-ef52-41ce-86cc-003831e3a241',
  email_date: 1.hour.ago
)

Site.create(
  site_name: "Stack Overflow",
  site_url: "//stackoverflow.com/",
  site_logo: "//cdn.sstatic.net/Sites/stackoverflow/img/apple-touch-icon.png",
  site_domain: "stackoverflow.com"
)

StackExchangeUser.create(
  user_id: -1,
  username: 'Community',
  last_api_update: 1.hour.ago,
  answer_count: 1,
  question_count: 1,
  reputation: 1,
  site_id: 1
)

Post.create(
  title: 'Test Post',
  body: 'Test Post',
  link: '//stackoverflow.com/a/40291627',
  post_creation_date: 1.hour.ago,
  site_id: 1,
  user_link: '//stackoverflow.com/users/-1',
  username: 'Community',
  user_reputation: 1,
  why: 'Why not?',
  score: 2,
  stack_exchange_user_id: 1
)

FlagSetting.create(
  name: 'flagging_enabled',
  value: '0'
)

FlagSetting.create(
  name: 'registration_enabled',
  value: '0'
)

FlagSetting.create(
  name: 'min_accuracy',
  value: '99'
)

FlagSetting.create(
  name: 'min_post_count',
  value: '1000'
)

FlagSetting.create(
  name: 'dry_run',
  value: '1'
)
