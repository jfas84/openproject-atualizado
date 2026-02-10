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

require "spec_helper"
require_relative "../../support/pages/backlogs"

RSpec.describe "Backlogs", :js do
  let(:story_type) do
    create(:type_feature)
  end
  let(:story_type2) do
    type = create(:type)

    project.types << type

    type
  end
  let(:inactive_story_type) do
    create(:type)
  end

  let(:task_type) do
    type = create(:type_task)
    project.types << type

    type
  end

  let(:user) do
    create(:user,
           member_with_permissions: { project => %i(add_work_packages
                                                    view_master_backlog
                                                    view_work_packages
                                                    assign_versions) })
  end
  let(:project) { create(:project) }

  let(:backlog_version) { create(:version, project:) }

  let!(:existing_story1) do
    create(:work_package,
           type: story_type,
           project:,
           status: default_status,
           priority: default_priority,
           position: 1,
           story_points: 3,
           version: backlog_version)
  end
  let!(:existing_story2) do
    create(:work_package,
           type: story_type,
           project:,
           status: default_status,
           priority: default_priority,
           position: 2,
           story_points: 4,
           version: backlog_version)
  end
  let!(:default_status) do
    create(:default_status)
  end
  let!(:default_priority) do
    create(:default_priority)
  end

  let(:backlogs_page) { Pages::Backlogs.new(project) }

  before do
    login_as(user)

    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
            .and_return("story_types" => [story_type.id.to_s,
                                          story_type2.id.to_s,
                                          inactive_story_type.id.to_s],
                        "task_type" => task_type.id.to_s)
  end

  it "allows creating a new story" do
    backlogs_page.visit!

    backlogs_page.click_in_backlog_menu(backlog_version, "New story")

    within_dialog "New work package" do
      fill_in "Subject", with: "The new story"
      # TODO: removed in OP #57688, to be reimplemented
      # fill_in "Story Points", with: "5"

      # inactive types should not be selectable but the user can choose from the
      # active types
      # TODO: removed in OP #57688, to be reimplemented
      # expect(page).to have_no_css("option", text: inactive_story_type.name)

      select_combo_box_option story_type2.name, from: "Type"

      # saving the new story
      click_on "Create"
    end

    expect_and_dismiss_flash type: :success, message: "New work package created"

    # velocity should be summed up immediately
    # TODO: removed in OP #57688, to be reimplemented
    # xpect(page).to have_css(".velocity", text: "12")

    # this will ensure that the page refresh is through before we check the order
    backlogs_page.click_in_backlog_menu(backlog_version, "New story")

    within_dialog "New work package" do
      fill_in "Subject", with: "Another story"
    end

    # the order is kept even after a page refresh -> it is persisted in the db
    page.driver.refresh

    expect(page)
      .to have_no_content "Another story"

    new_story = WorkPackage.find_by(subject: "The new story")

    # stories are ordered by position (ASC), with NULL positions at the end ordered by ID
    # existing stories have positions 1 and 2, new story has no position so appears at end
    backlogs_page.expect_stories_in_order(backlog_version, existing_story1, existing_story2, new_story)

    # created with the selected type (HighlightedTypeComponent renders type name in uppercase)
    within("#story_#{new_story.id}") do
      expect(page).to have_text(story_type2.name.upcase)
    end
  end
end
