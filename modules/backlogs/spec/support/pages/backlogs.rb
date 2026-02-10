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

require "support/pages/page"

module Pages
  class Backlogs < Page
    attr_reader :project

    def initialize(project)
      super()
      @project = project
    end

    def enter_edit_backlog_mode(backlog)
      within_backlog_menu(backlog) do |menu|
        menu.find(:menuitem, "Edit sprint").click
      end
    end

    def alter_attributes_in_details_view(story, **attributes)
      within_details_view(story) do |details_view|
        attributes.each do |key, value|
          details_view
            .edit_field(key.to_s.camelize(:lower))
            .update(value) # rubocop:disable Rails/SaveBang

          details_view.expect_and_dismiss_toaster message: "Successful update."
        end
      end
    end

    def alter_attributes_in_edit_backlog_mode(backlog, **attributes)
      within_backlog(backlog) do
        attributes.each do |key, value|
          case key
          when :name
            fill_in "Name", with: value
          when :start_date
            fill_in "Start date", with: value
          when :effective_date
            fill_in "Finish date", with: value
          else
            raise NotImplementedError
          end
        end
      end
    end

    def save_backlog_from_edit_mode(backlog)
      within_backlog(backlog) do
        find_field("Name").send_keys :return
      end
    end

    def edit_backlog(backlog, **attributes)
      enter_edit_backlog_mode(backlog)

      alter_attributes_in_edit_backlog_mode(backlog, **attributes)

      save_backlog_from_edit_mode(backlog)
    end

    def edit_story_in_details_view(story, **attributes)
      click_in_story_menu(story, "Open details view")

      alter_attributes_in_details_view(story, **attributes)
    end

    def click_in_backlog_menu(backlog, item_name)
      within_backlog_menu(backlog) do |menu|
        menu.find(:menuitem, text: item_name).click
      end
    end

    def click_in_story_menu(story, item_name)
      within_story_menu(story) do |menu|
        menu.find(:menuitem, text: item_name).click
      end
    end

    def drag_in_sprint(moved, target, before: true)
      moved_element = find(story_selector(moved))
      target_element = find(story_selector(target))

      drag_n_drop_element from: moved_element, to: target_element, offset_x: 0, offset_y: before ? -5 : +10
    end

    def fold_backlog(backlog)
      within_backlog(backlog) do
        find(:button, accessible_name: "Collapse/Expand #{backlog.name}").click
      end
    end

    def expect_sprint(sprint)
      expect(page)
        .to have_css("#sprint_backlogs_container #{backlog_selector(sprint)}")
    end

    def expect_backlog(sprint)
      expect(page)
        .to have_css("#owner_backlogs_container #{backlog_selector(sprint)}")
    end

    def expect_story_in_sprint(story, sprint)
      within_backlog(sprint) do
        expect(page)
          .to have_selector(story_selector(story).to_s)
      end
    end

    def expect_story_not_in_sprint(story, sprint)
      within_backlog(sprint) do
        expect(page)
          .to have_no_selector(story_selector(story).to_s)
      end
    end

    def expect_velocity(backlog, velocity)
      within("#backlog_#{backlog.id} .velocity") do
        expect(page)
          .to have_content(velocity.to_s)
      end
    end

    def expect_stories_in_order(backlog, *stories)
      within_backlog(backlog) do
        ids = stories.map { |s| "story_#{s.id}" }
        existing_ids_in_order = all(ids.map { |id| "##{id}" }.join(", ")).pluck(:id)

        expect(existing_ids_in_order)
          .to eql(ids)
      end
    end

    def expect_and_dismiss_error(message)
      expect(page).to have_content message

      click_on "Cancel"
    end

    def path
      backlogs_project_backlogs_path(project)
    end

    def within_backlog_menu(backlog, &)
      within_backlog(backlog) do
        find(:button, accessible_name: "Backlog actions").click

        within(:menu, &)
      end
    end

    def within_story_menu(story, &)
      within_story(story) do
        find(:button, accessible_name: "Story actions").click

        within(:menu, &)
      end
    end

    def within_details_view(story, &)
      details_view = Pages::PrimerizedSplitWorkPackage.new(story)
      details_view.expect_tab :overview
      details_view.expect_subject

      expect(page).to have_current_path details_backlogs_project_backlogs_path(story.project, story)

      yield details_view
    end

    private

    def within_story(story, &)
      within(story_selector(story), &)
    end

    def within_backlog(backlog, &)
      within(backlog_selector(backlog), &)
    end

    def backlog_selector(backlog)
      "#backlog_#{backlog.id}"
    end

    def story_selector(story)
      "#story_#{story.id}"
    end
  end
end
