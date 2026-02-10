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

class My::BacklogsForm < ApplicationForm
  form do |f|
    f.text_field name: :task_color,
                 label: I18n.t("backlogs.task_color"),
                 value: @color,
                 input_width: :xsmall

    f.check_box name: :versions_default_fold_state,
                value: DEFAULT_FOLD_STATE,
                checked: default_fold_state_checked?,
                label: I18n.t("backlogs.label_versions_default_fold_state"),
                caption: I18n.t("backlogs.caption_versions_default_fold_state")

    f.submit(name: :submit, label: I18n.t("backlogs.user_preference.button_update_backlogs"), scheme: :default)
  end

  DEFAULT_FOLD_STATE = "closed"

  def initialize(color:, versions_default_fold_state:)
    super()
    @color = color
    @versions_default_fold_state = versions_default_fold_state
  end

  private

  def default_fold_state_checked?
    @versions_default_fold_state == DEFAULT_FOLD_STATE
  end
end
