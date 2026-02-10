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

module WorkPackageTypes
  class FormConfigurationTabController < BaseTabController
    include PaginationHelper

    layout "admin"

    current_menu_item [:edit, :update] do
      :types
    end

    def edit; end

    def update
      result = WorkPackageTypes::UpdateService
        .new(user: current_user, model: @type, contract_class: UpdateFormConfigurationContract)
        .call(permitted_type_params)

      if result.success?
        redirect_to edit_type_form_configuration_path(@type), notice: t(:notice_successful_update)
      else
        flash.now[:error] = result.errors[:attribute_groups].to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def find_type
      @type = ::Type.includes(:projects, :custom_fields).find(params[:type_id])
      show_error_not_found unless @type
    end

    def permitted_type_params
      # having to call #to_unsafe_h as a query hash the attribute_groups
      # parameters would otherwise still be an ActiveSupport::Parameter
      permitted_params.type.to_unsafe_h
    end
  end
end
