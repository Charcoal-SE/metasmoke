# frozen_string_literal: true
require 'redcarpet'

renderer = Redcarpet::Render::HTML.new hard_wrap: true
parser = Redcarpet::Markdown.new renderer

output = %w[<table> <tbody> <thead> <tr><td><strong>Path</strong></td><td><strong>Description</strong></td></tr>]
Dir.glob('../docs/**/*.md').sort_by { |x| File.basename x }.each do |f|
  text = File.read f
  title = Regexp.new(/^# ?([\w ]+)$/).match(text)[1]

  output << "<tr><td><strong>#{title}</strong></td><td></td></tr>"

  routes = text.split("---\n").reject { |x| x.nil? || x == '' }
  routes.shift

  routes.each do |r|
    splat = r.split("\n")
    meta = splat.shift.split '|'
    url = meta[0]
    desc = meta[1]
    details = parser.render(splat.join("\n"))
    output << "<tr><td><code>#{url}</code></td><td><details><summary>#{desc}</summary>#{details}</details></td></tr>"
  end
end
output << '</tbody>'
output << '</table>'

puts output
