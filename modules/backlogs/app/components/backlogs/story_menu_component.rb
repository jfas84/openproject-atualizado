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
  class StoryMenuComponent < ApplicationComponent
    attr_reader :story, :sprint, :project, :max_position, :current_user

    def initialize(story:, sprint:, max_position:, current_user: User.current)
      super()

      @story = story
      @sprint = sprint
      @project = sprint.project
      @max_position = max_position
      @current_user = current_user
    end

    private

    def show_move_items?
      !(first_item? && last_item?)
    end

    def build_move_menu(menu)
      unless first_item?
        build_move_item(menu, label: I18n.t(:label_sort_highest), direction: "highest", icon: :"move-to-top")
        build_move_item(menu, label: I18n.t(:label_sort_higher), direction: "higher", icon: :"chevron-up")
      end
      unless last_item?
        build_move_item(menu, label: I18n.t(:label_sort_lower), direction: "lower", icon: :"chevron-down")
        build_move_item(menu, label: I18n.t(:label_sort_lowest), direction: "lowest", icon: :"move-to-bottom")
      end
    end

    def build_move_item(menu, label:, direction:, icon:)
      menu.with_item(
        label:,
        tag: :button,
        href: reorder_backlogs_project_sprint_story_path(project, sprint, story),
        form_arguments: { method: :post, inputs: [{ name: "direction", value: direction }] }
      ) do |item|
        item.with_leading_visual_icon(icon:)
      end
    end

    def first_item?
      story.position == 1
    end

    def last_item?
      story.position == max_position
    end
  end
end
