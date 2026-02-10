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

class RbStoriesController < RbApplicationController
  include OpTurbo::ComponentStream

  before_action :load_story

  def move # rubocop:disable Metrics/AbcSize
    # The update service reloads the story internally (via #move_after),
    # so we memoize the previous version_id before the call.
    version_id_was = @story.version_id

    call = Stories::UpdateService
      .new(user: current_user, story: @story)
      .call(
        attributes: { version_id: move_params[:target_id] },
        position: move_params[:position].to_i
      )

    unless call.success?
      render_error_flash_message_via_turbo_stream(
        message: I18n.t(:notice_unsuccessful_update_with_reason, reason: call.message)
      )
    end

    replace_backlog_component_via_turbo_stream(sprint: @sprint)

    if @story.version_id != version_id_was
      new_sprint = @story.version.becomes(Sprint)

      render_success_flash_message_via_turbo_stream(
        message: I18n.t(:notice_successful_move, from: @sprint.name, to: new_sprint.name)
      )
      replace_backlog_component_via_turbo_stream(sprint: new_sprint)
    end

    respond_with_turbo_streams
  end

  def reorder
    call = Stories::UpdateService
      .new(user: current_user, story: @story)
      .call(attributes: { move_to: reorder_param })

    unless call.success?
      render_error_flash_message_via_turbo_stream(
        message: I18n.t(:notice_unsuccessful_update_with_reason, reason: call.message)
      )
    end

    replace_backlog_component_via_turbo_stream(sprint: @sprint)

    respond_with_turbo_streams
  end

  private

  def replace_backlog_component_via_turbo_stream(sprint:)
    @backlog = Backlog.for(sprint:, project: @project)
    replace_via_turbo_stream(component: Backlogs::BacklogComponent.new(backlog: @backlog, project: @project))
  end

  def load_story
    @story = Story.visible.find(params[:id])
  end

  def move_params
    params.require(%i[position target_id])
    params.permit(:position, :target_id)
  end

  def reorder_param
    params.expect(:direction)
  end
end
