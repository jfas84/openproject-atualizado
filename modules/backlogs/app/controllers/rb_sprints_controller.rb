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

class RbSprintsController < RbApplicationController
  include OpTurbo::ComponentStream

  def edit_name
    update_header_component_via_turbo_stream(state: :edit)
    respond_with_turbo_streams
  end

  def show_name
    update_header_component_via_turbo_stream(state: :show)
    respond_with_turbo_streams
  end

  def update
    call = Versions::UpdateService
      .new(user: current_user, model: @sprint)
      .call(attributes: sprint_params)

    if call.success?
      status = 200
      state = :show
      @sprint = call.result
      render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_update))
    else
      status = 422
      state = :edit
      render_error_flash_message_via_turbo_stream(
        message: I18n.t(:notice_unsuccessful_update_with_reason, reason: call.message)
      )
    end

    update_header_component_via_turbo_stream(state:)
    respond_with_turbo_streams(status:)
  end

  private

  def update_header_component_via_turbo_stream(state: :show)
    @backlog = Backlog.for(sprint: @sprint, project: @project)

    update_via_turbo_stream(
      component: Backlogs::BacklogHeaderComponent.new(
        backlog: @backlog,
        project: @project,
        state:
      )
    )
  end

  # Overrides load_sprint_and_project to load the sprint from :id instead of :sprint_id
  def load_sprint_and_project
    @sprint = Sprint.visible.find(params[:id])
    @project = @sprint.project
    # This overrides sprint's project if we set another project, say a subproject
    @project = Project.visible.find(params[:project_id])
  end

  def sprint_params
    params.expect(sprint: %i[name start_date effective_date])
  end
end
