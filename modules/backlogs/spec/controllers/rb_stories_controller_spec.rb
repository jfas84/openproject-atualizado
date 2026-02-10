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

RSpec.describe RbStoriesController do
  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:type_task) { create(:type_task) }
  shared_let(:user) { create(:admin) }
  current_user { user }

  let(:project) { create(:project) }
  let(:status)  { create(:status, name: "status 1", is_default: true) }
  let(:sprint)  { create(:sprint, project:) }
  let(:story)   { create(:story, status:, version: sprint, project:) }

  before do
    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
      .and_return({ "story_types" => [type_feature.id], "task_type" => type_task.id })
  end

  describe "PUT #move" do
    let(:other_sprint) { create(:sprint, name: "Sprint 2", project:) }

    it "responds with success", :aggregate_failures do
      put :move, params: {
                   project_id: project.id,
                   sprint_id: sprint.id,
                   id: story.id,
                   target_id: other_sprint.id,
                   position: 1
                 },
                 format: :turbo_stream

      expect(response).to be_successful
      expect(response).to have_http_status :ok
      expect(response).to have_turbo_stream action: "replace", target: "backlogs-backlog-component-#{sprint.id}"
      expect(response).to have_turbo_stream action: "replace", target: "backlogs-backlog-component-#{other_sprint.id}"
      expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
      expect(assigns(:project)).to eq(project)
      expect(assigns(:sprint)).to eq(sprint)
      expect(assigns(:story)).to eq(story)
      expect(assigns(:backlog)).to be_a(Backlog)
    end

    context "when service call fails" do
      let(:service_result) { ServiceResult.failure(message: "Something went wrong") }

      before do
        update_service = instance_double(Stories::UpdateService, call: service_result)

        allow(Stories::UpdateService)
          .to receive(:new)
          .and_return(update_service)
      end

      it "renders an error flash", :aggregate_failures do
        put :move, params: {
                     project_id: project.id,
                     sprint_id: sprint.id,
                     id: story.id,
                     target_id: other_sprint.id,
                     position: 1
                   },
                   format: :turbo_stream

        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "replace", target: "backlogs-backlog-component-#{sprint.id}"
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
      end
    end
  end

  describe "POST #reorder" do
    it "responds with success", :aggregate_failures do
      post :reorder, params: { project_id: project.id, sprint_id: sprint.id, id: story.id, direction: "highest" },
                     format: :turbo_stream

      expect(response).to be_successful
      expect(response).to have_http_status :ok
      expect(response).to have_turbo_stream action: "replace", target: "backlogs-backlog-component-#{sprint.id}"
      expect(assigns(:project)).to eq(project)
      expect(assigns(:sprint)).to eq(sprint)
      expect(assigns(:story)).to eq(story)
      expect(assigns(:backlog)).to be_a(Backlog)
    end

    context "when service call fails" do
      let(:service_result) { ServiceResult.failure(message: "Something went wrong") }

      before do
        update_service = instance_double(Stories::UpdateService, call: service_result)

        allow(Stories::UpdateService)
          .to receive(:new)
          .and_return(update_service)
      end

      it "renders an error flash", :aggregate_failures do
        post :reorder, params: { project_id: project.id, sprint_id: sprint.id, id: story.id, direction: "highest" },
                       format: :turbo_stream

        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "replace", target: "backlogs-backlog-component-#{sprint.id}"
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
      end
    end
  end
end
