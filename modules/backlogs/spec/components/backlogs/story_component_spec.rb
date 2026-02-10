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

require "rails_helper"

RSpec.describe Backlogs::StoryComponent, type: :component do
  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:type_task) { create(:type_task) }
  shared_let(:default_status) { create(:default_status) }
  shared_let(:default_priority) { create(:default_priority) }
  shared_let(:user) { create(:admin) }
  current_user { user }

  let(:project) { create(:project, types: [type_feature, type_task]) }
  let(:sprint) { create(:sprint, project:, name: "Sprint 1", start_date: Date.yesterday, effective_date: Date.tomorrow) }
  let(:story_points) { 5 }
  let(:story) do
    create(:story,
           subject: "Test Story Subject",
           project:,
           type: type_feature,
           status: default_status,
           priority: default_priority,
           story_points:,
           position: 1,
           version: sprint)
  end
  let(:max_position) { 3 }

  before do
    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
      .and_return("story_types" => [type_feature.id.to_s], "task_type" => type_task.id.to_s)
  end

  def render_component
    render_inline(described_class.new(story:, sprint:, max_position:, current_user: user))
  end

  describe "rendering" do
    it "renders Primer::OpenProject::DragHandle" do
      render_component

      # DragHandle renders with grabber icon
      expect(page).to have_octicon(:grabber)
    end

    it "renders WorkPackages::InfoLineComponent" do
      render_component

      # InfoLine renders type and ID info
      expect(page).to have_text("FEATURE")
      expect(page).to have_text("##{story.id}")
    end

    it "shows story subject in semibold text" do
      render_component

      expect(page).to have_text("Test Story Subject")
    end

    it "shows story points" do
      render_component

      expect(page).to have_text("5 points", normalize_ws: true)
    end

    it "renders StoryMenuComponent" do
      render_component

      expect(page).to have_css("action-menu")
    end
  end

  describe "story points handling" do
    context "when story_points is nil" do
      let(:story_points) { nil }

      it "shows 0 points" do
        render_component

        expect(page).to have_text("0 points", normalize_ws: true)
      end
    end

    context "when story_points is 0" do
      let(:story_points) { 0 }

      it "shows 0 points" do
        render_component

        expect(page).to have_text("0 points", normalize_ws: true)
      end
    end

    context "when story_points is 1" do
      let(:story_points) { 1 }

      it "shows 1 point (singular)" do
        render_component

        expect(page).to have_text("1 point", normalize_ws: true)
      end
    end
  end
end
