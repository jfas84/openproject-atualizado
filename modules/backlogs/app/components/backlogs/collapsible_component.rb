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

module Backlogs
  class CollapsibleComponent < Primer::Component
    include OpPrimer::ComponentHelpers

    renders_one :title, ->(**system_arguments) {
      system_arguments[:classes] = class_names(
        system_arguments[:classes],
        "op-backlogs-collapsible--title",
        "Box-title"
      )

      Primer::Beta::Truncate.new(tag: :h3, **system_arguments)
    }

    renders_one :count, ->(**system_arguments) {
      system_arguments[:mr] ||= 2
      system_arguments[:scheme] ||= :primary
      system_arguments[:classes] = class_names(
        system_arguments[:classes],
        "op-backlogs-collapsible--count"
      )

      Primer::Beta::Counter.new(**system_arguments)
    }

    renders_one :description, ->(**system_arguments) {
      system_arguments[:color] ||= :subtle
      system_arguments[:hidden] = @collapsed
      system_arguments[:classes] = class_names(
        system_arguments[:classes],
        "op-backlogs-collapsible--description"
      )

      Primer::Beta::Text.new(**system_arguments)
    }

    def initialize(collapsible_id:, toggle_label:, collapsed: false, **system_arguments)
      super()

      @collapsible_id = collapsible_id
      @toggle_label = toggle_label
      @collapsed = collapsed

      @system_arguments = deny_tag_argument(**system_arguments)
      @system_arguments[:tag] = :"collapsible-header"
      @system_arguments[:classes] = class_names(
        system_arguments[:classes],
        "CollapsibleHeader",
        "CollapsibleHeader--collapsed" => @collapsed
      )
      if @collapsed
        @system_arguments[:data] = merge_data(
          @system_arguments, {
            data: { collapsed: @collapsed }
          }
        )
      end
    end
  end
end
