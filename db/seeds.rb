# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

SmokeDetector.create(last_ping: 1.hour.ago, name: 'Seed', location: 'Nowhere', access_token: '9b104345-ef52-41ce-86cc-003831e3a241', email_date: 1.hour.ago)
