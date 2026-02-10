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

require "spec_helper"
require_relative "../../support/pages/backlogs"

RSpec.describe "Backlogs context menu", :js do
  shared_let(:story_type) { create(:type_feature) }
  shared_let(:task_type) { create(:type_task) }
  shared_let(:project) { create(:project, types: [story_type, task_type]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[add_work_packages
                                                    view_master_backlog
                                                    view_taskboards
                                                    view_work_packages] })
  end
  shared_let(:sprint) do
    create(:version,
           project:,
           name: "Sprint",
           start_date: Date.yesterday,
           effective_date: Date.tomorrow)
  end
  shared_let(:default_status) { create(:default_status) }
  shared_let(:default_priority) { create(:default_priority) }
  shared_let(:story) do
    create(:work_package,
           type: story_type,
           project:,
           status: default_status,
           priority: default_priority,
           position: 1,
           story_points: 3,
           version: sprint)
  end

  before do
    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
            .and_return("story_types" => [story_type.id.to_s],
                        "task_type" => task_type.id.to_s)
    login_as(user)
  end

  let(:backlogs_page) { Pages::Backlogs.new(project) }

  def within_backlog_context_menu(&)
    backlogs_page.visit!
    backlogs_page.within_backlog_menu(sprint, &)
  end

  context "when the backlog is a sprint backlog (displayed on the left, the default)" do
    it "displays all menu entries" do
      within_backlog_context_menu do |menu|
        expect(menu).to have_selector :menuitem, count: 5
        expect(menu).to have_selector :menuitem, "New story"
        expect(menu).to have_selector :menuitem, "Stories/Tasks"
        expect(menu).to have_selector :menuitem, "Task board"
        expect(menu).to have_selector :menuitem, "Burndown chart"
        expect(menu).to have_selector :menuitem, "Wiki"
      end
    end
  end

  context "when the backlog is an owner backlog (displayed on the right)" do
    let!(:version_setting) do
      create(:version_setting,
             project:,
             version: sprint,
             display: VersionSetting::DISPLAY_RIGHT)
    end

    it "only displays 2 menu entries" do
      within_backlog_context_menu do |menu|
        expect(menu).to have_selector :menuitem, count: 2
        expect(menu).to have_selector :menuitem, "New story"
        expect(menu).to have_selector :menuitem, "Stories/Tasks"
        expect(menu).to have_no_selector :menuitem, "Task board"
        expect(menu).to have_no_selector :menuitem, "Burndown chart"
        expect(menu).to have_no_selector :menuitem, "Wiki"
      end
    end
  end

  context "when the sprint does not have a start date" do
    before do
      sprint.update(start_date: nil)
    end

    it 'disables the "Burndown chart" menu entry' do
      within_backlog_context_menu do |menu|
        expect(menu).to have_selector :menuitem, "Burndown chart", disabled: true
      end
    end
  end

  context "when the sprint does not have an effective date" do
    before do
      sprint.update(effective_date: nil)
    end

    it 'disables the "Burndown chart" menu entry' do
      within_backlog_context_menu do |menu|
        expect(menu).to have_selector :menuitem, "Burndown chart", disabled: true
      end
    end
  end

  context "when the user does not have add_work_packages permission" do
    before do
      RolePermission.where(permission: "add_work_packages").delete_all
    end

    it 'does not display the "New story" menu entry' do
      within_backlog_context_menu do |menu|
        expect(menu).to have_no_selector :menuitem, "New story"
      end
    end
  end

  context "when the user does not have view_taskboards permission" do
    before do
      RolePermission.where(permission: "view_taskboards").delete_all
    end

    it 'does not display the "Task board" menu entry' do
      within_backlog_context_menu do |menu|
        expect(menu).to have_no_selector :menuitem, "Task board"
      end
    end
  end

  context "when the wiki module is not enabled" do
    before do
      project.enabled_module_names -= ["wiki"]
    end

    it 'does not display the "Wiki" menu entry' do
      within_backlog_context_menu do |menu|
        expect(menu).to have_no_selector :menuitem, "Wiki"
      end
    end
  end
end
