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

RSpec.describe Backlogs::StoryMenuComponent, type: :component do
  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:type_task) { create(:type_task) }
  shared_let(:default_status) { create(:default_status) }
  shared_let(:default_priority) { create(:default_priority) }
  shared_let(:user) { create(:admin) }
  current_user { user }

  let(:project) { create(:project, types: [type_feature, type_task]) }
  let(:sprint) { create(:sprint, project:, name: "Sprint 1", start_date: Date.yesterday, effective_date: Date.tomorrow) }
  let(:position) { 2 }
  let(:max_position) { 3 }
  let(:story) do
    create(:story,
           subject: "Test Story",
           project:,
           type: type_feature,
           status: default_status,
           priority: default_priority,
           story_points: 5,
           position:,
           version: sprint)
  end

  before do
    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
      .and_return("story_types" => [type_feature.id.to_s], "task_type" => type_task.id.to_s)
  end

  def render_component(position: 2, max_position: 3)
    story.update!(position:)
    render_inline(described_class.new(story:, sprint:, max_position:, current_user: user))
  end

  describe "standard items" do
    it "shows Open details link (split view)" do
      render_component

      expect(page).to have_text(I18n.t(:"js.button_open_details"))
      expect(page).to have_octicon(:"op-view-split")
    end

    it "shows Open fullscreen link (full page)" do
      render_component

      expect(page).to have_text(I18n.t(:"js.button_open_fullscreen"))
      expect(page).to have_octicon(:"screen-full")
    end

    it "shows a divider before move options" do
      render_component

      expect(page).to have_css(".ActionList-sectionDivider")
    end
  end

  describe "move menu items" do
    it "shows Move to top item with move-to-top icon" do
      render_component

      expect(page).to have_text(I18n.t(:label_sort_highest))
      expect(page).to have_octicon(:"move-to-top")
    end

    it "shows Move up item with chevron-up icon" do
      render_component

      expect(page).to have_text(I18n.t(:label_sort_higher))
      expect(page).to have_octicon(:"chevron-up")
    end

    it "shows Move down item with chevron-down icon" do
      render_component

      expect(page).to have_text(I18n.t(:label_sort_lower))
      expect(page).to have_octicon(:"chevron-down")
    end

    it "shows Move to bottom item with move-to-bottom icon" do
      render_component

      expect(page).to have_text(I18n.t(:label_sort_lowest))
      expect(page).to have_octicon(:"move-to-bottom")
    end
  end

  describe "position logic" do
    context "when item is first (position=1)" do
      it "hides Move to top and Move up" do
        render_component(position: 1, max_position: 3)

        expect(page).to have_no_text(I18n.t(:label_sort_highest))
        expect(page).to have_no_text(I18n.t(:label_sort_higher))
      end

      it "shows Move down and Move to bottom" do
        render_component(position: 1, max_position: 3)

        expect(page).to have_text(I18n.t(:label_sort_lower))
        expect(page).to have_text(I18n.t(:label_sort_lowest))
      end
    end

    context "when item is last (position=max)" do
      it "hides Move down and Move to bottom" do
        render_component(position: 3, max_position: 3)

        expect(page).to have_no_text(I18n.t(:label_sort_lower))
        expect(page).to have_no_text(I18n.t(:label_sort_lowest))
      end

      it "shows Move to top and Move up" do
        render_component(position: 3, max_position: 3)

        expect(page).to have_text(I18n.t(:label_sort_highest))
        expect(page).to have_text(I18n.t(:label_sort_higher))
      end
    end

    context "when item is in the middle" do
      it "shows all move options" do
        render_component(position: 2, max_position: 3)

        expect(page).to have_text(I18n.t(:label_sort_highest))
        expect(page).to have_text(I18n.t(:label_sort_higher))
        expect(page).to have_text(I18n.t(:label_sort_lower))
        expect(page).to have_text(I18n.t(:label_sort_lowest))
      end
    end

    context "when there is only one item (position=1, max=1)" do
      it "hides all move options" do
        render_component(position: 1, max_position: 1)

        expect(page).to have_no_text(I18n.t(:label_sort_highest))
        expect(page).to have_no_text(I18n.t(:label_sort_higher))
        expect(page).to have_no_text(I18n.t(:label_sort_lower))
        expect(page).to have_no_text(I18n.t(:label_sort_lowest))
      end

      it "hides the divider" do
        render_component(position: 1, max_position: 1)

        expect(page).to have_no_css(".ActionList-sectionDivider")
      end
    end
  end
end
