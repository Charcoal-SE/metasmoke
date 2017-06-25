# frozen_string_literal: true

include ERB::Util

module ApplicationHelper
  def title(text)
    content_for :title, text
    text
  end

  def current_action?(cls, action = nil)
    return false unless controller.is_a? cls
    return controller.action_name == action.to_s if action
    true
  end

  @current_dropdown = nil
  def nav_link(cls, options = {}, &block)
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
    else
      url = '#'
    end

    options[:label] = options[:label].to_s
    options[:label] = options[:label].titleize.sub 'Smoke Detector', 'SmokeDetector' if @current_dropdown

    link = if block_given?
             link_to(url, options[:link_attrs]) { h(options[:label]) + ' ' + capture(&block) }
           else
             link_to options[:label], url, options[:link_attrs]
           end

    actives = options[:active]
              .clone
              .unshift([cls, options[:action]])
              .reject { |item| item.nil? || (item.is_a?(Array) && item[0].nil?) }
              .map { |item| item.is_a?(Array) ? item : [item, nil] }

    @current_dropdown.concat actives if @current_dropdown

    is_active = !actives.select { |args| current_action?(*args) }.empty?

    tag.li link + options[:children], options[:attrs].merge(class: [is_active ? 'active' : '', *options[:attrs][:class]])
  end

  def nav_dropdown(cls = nil, options = {}, &block)
    if cls.is_a? Hash
      options = cls
      cls = nil
    end

    @current_dropdown = []
    children = capture(&block)
    actives = @current_dropdown
    @current_dropdown = nil

    nav_link(
      cls,
      options.merge(
        active: actives,
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
end
