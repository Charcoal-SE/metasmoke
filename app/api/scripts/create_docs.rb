# frozen_string_literal: true

require 'commonmarker'

def render_markdown(text)
  CommonMarker.render_html(text, %i[UNSAFE HARDBREAKS], %i[autolink tagfilter])
end

output = %w[<table> <thead> <tr><td><strong>Path</strong></td><td><strong>Description</strong></td></tr> </thead> <tbody>]
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
    details = render_markdown(splat.join("\n"))
    output << "<tr><td><code>#{url}</code></td><td><details><summary>#{desc}</summary>#{details}</details></td></tr>"
  end
end
output << '</tbody>'
output << '</table>'

puts output
