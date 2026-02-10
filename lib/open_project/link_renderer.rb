# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  class LinkRenderer < ::WillPaginate::ActionView::LinkRenderer
    include ActionView::Helpers::OutputSafetyHelper

    protected

    def merge_get_params(url_params)
      params = super
      allowed_params ? params.slice(*allowed_params) : params
    end

    def page_number(page)
      label = I18n.t("js.pagination.pages.page_number", number: page)
      if page == current_page
        tag(:li,
            tag(:em, page, "aria-label": label, "aria-current": "page", tabindex: 0),
            class: "op-pagination--item op-pagination--item_current")
      else
        tag(:li,
            link(page, page, class: "op-pagination--item-link", "aria-label": label),
            class: "op-pagination--item")
      end
    end

    def gap
      tag(:li,
          tag(:span, "&#x2026;", "aria-hidden": "true") +
          tag(:span, I18n.t(:"js.pagination.pages_skipped"), class: "sr-only"),
          class: "op-pagination--space")
    end

    def previous_page
      num = @collection.current_page > 1 && (@collection.current_page - 1)
      previous_or_next_page(
        num,
        safe_join_components(
          render_octicon(:"chevron-left", class_suffix: "prev"),
          I18n.t(:label_previous)
        ),
        "prev"
      )
    end

    def next_page
      num = @collection.current_page < total_pages && (@collection.current_page + 1)
      previous_or_next_page(
        num,
        safe_join_components(
          I18n.t(:label_next),
          render_octicon(:"chevron-right", class_suffix: "next")
        ),
        "next"
      )
    end

    def previous_or_next_page(page, text, class_suffix)
      if page
        tag(:li,
            link(text, page, { class: "op-pagination--item-link op-pagination--item-link_#{class_suffix}" }),
            class: "op-pagination--item")
      else
        ""
      end
    end

    private

    def link(text, target, attributes)
      new_attributes = attributes.dup
      new_attributes["data-turbo-stream"] = true if turbo?
      new_attributes["data-turbo-action"] = turbo_action if turbo_action.present?

      super(text, target, new_attributes)
    end

    def allowed_params
      @options[:allowed_params]
    end

    # Customize the Turbo visit action for pagination links. Can be set to "advance" or "replace".
    #  "advance" - push a new entry onto the history stack.
    #  "replace" - replace the current history entry.
    # See: https://turbo.hotwired.dev/reference/attributes
    #
    # Example: Promoting a Frame Navigation to a Page Visit
    #   By default navigation within a turbo frame does not change the rest of the browser's state,
    #   but you can promote a frame navigation a "Visit" by setting the turbo-action attribute to "advance".
    #   See: https://turbo.hotwired.dev/handbook/frames#promoting-a-frame-navigation-to-a-page-visit
    #
    def turbo_action
      @options[:turbo_action]
    end

    def turbo?
      @options[:turbo]
    end

    def safe_join_components(*components)
      safe_join(components, " ")
    end

    def render_octicon(icon_name, class_suffix:, **)
      @template.render(
        Primer::Beta::Octicon.new(
          icon_name,
          size: :xsmall,
          classes: ["op-pagination--item-link-icon", "op-pagination--item-link-icon_#{class_suffix}"],
          **
        )
      )
    end
  end
end
