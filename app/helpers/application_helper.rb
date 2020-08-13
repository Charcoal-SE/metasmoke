# frozen_string_literal: true

require 'singleton'
include ERB::Util

module ApplicationHelper
  class PostMap
    include Singleton

    def initialize
      @url_post_map = {}
    end

    def drop_map!
      @url_post_map = {}
    end

    def add_post(post)
      return if post.link.blank?
      @url_post_map.key?(post.link) || @url_post_map[post.link] = []
      @url_post_map[post.link].push(post.id).uniq
    end

    def search(url)
      @url_post_map[url]
    end
  end

  def title(text)
    content_for :title, text
    text
  end

  def render_markdown(text)
    CommonMarker.render_doc(text,
                            %i[LIBERAL_HTML_TAG],
                            %i[autolink tagfilter]).to_html(:UNSAFE)
  end

  def safe_render_markdown(text, options = {})
    scrubber = options[:scrubber] || PostScrubber.new
    raw(sanitize(render_markdown(text), scrubber: scrubber))
  end

  @current_dropdown_is_active = nil
  def nav_link(cls, options = {}, &block)
    Rack::MiniProfiler.step("Generating nav_link: #{cls}") do
      options[:active] ||= []
      options[:attrs] ||= {}
      options[:attrs][:class] ||= []
      options[:action] ||= :index
      cls ||= options[:controller]

      if cls
        controller_name = cls.name.underscore.sub(/_controller$/, '')
        if options[:label].nil?
          options[:label] = if options[:action] == :index
                              controller_name
                            else
                              options[:action]
                            end
        end
        allowed_keys = %w[action anchor only_path].map(&:to_sym)
        url = url_for({
          # needs to be /#{controller_name} because otherwise, when you’re in a
          # scoped controller (e.g. devise/*), it looks for `devise/#{controller_name}`
          controller: "/#{controller_name}"
        }.merge(options.select { |key| allowed_keys.include? key })
         .merge(options[:params] || {}))
      elsif options[:path].present?
        url = options[:path]
      else
        url = '#'
      end

      options[:label] = options[:label].to_s
      options[:label] = options[:label].sub 'Smoke Detector', 'SmokeDetector' unless @current_dropdown_is_active.nil?

      link = if block_given?
               link_to(url, options[:link_attrs]) { h(options[:label]) + ' ' + capture(&block) }
             else
               link_to options[:label], url, options[:link_attrs]
             end

      if [true, false].include? options[:active]
        is_active = options[:active]
      else
        actives = options[:active]
                  .clone
                  .unshift([cls, options[:action]])
                  .reject { |item| item.nil? || (item.is_a?(Array) && item[0].nil?) }
                  .map { |item| item.is_a?(Array) ? item : [item, nil] }

        is_active = !actives.select { |args| current_action?(*args) }.empty?
      end

      @current_dropdown_is_active ||= is_active unless @current_dropdown_is_active.nil?

      tag.li link + options[:children], options[:attrs].merge(class: [is_active ? 'active' : '', *options[:attrs][:class]])
    end
  end

  def nav_dropdown(cls = nil, options = {}, &block)
    if cls.is_a? Hash
      options = cls
      cls = nil
    end

    @current_dropdown_is_active = false
    children = capture(&block)
    is_active = @current_dropdown_is_active
    @current_dropdown_is_active = nil

    nav_link(
      cls,
      options.merge(
        active: !!is_active, # rubocop:disable Style/DoubleNegation
        attrs: {
          class: 'dropdown'
        },
        link_attrs: {
          class: 'dropdown-toggle',
          data: {
            toggle: 'dropdown'
          },
          role: 'button',
          aria: {
            haspopup: true,
            expanded: false
          }
        },
        children: tag.ul(children, class: 'dropdown-menu')
      )
    ) { tag.span class: 'caret' }
  end

  protected

  def current_action?(cls, action = nil)
    return false unless controller.is_a? cls
    return controller.action_name == action.to_s if action
    true
  end
end
