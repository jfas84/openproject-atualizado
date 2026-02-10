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

module ScimV2
  module BaseControllerActions
    extend ActiveSupport::Concern

    included do
      skip_before_action :verify_authenticity_token

      rescue_from "ActiveRecord::RecordNotFound", with: :handle_resource_not_found

      def index
        query = if params[:filter].blank?
                  storage_scope
                else
                  attribute_map = storage_class.new.scim_queryable_attributes
                  parser        = ::Scimitar::Lists::QueryParser.new(attribute_map)

                  parser.parse(params[:filter])
                  parser.to_activerecord_query(storage_scope)
                end

        pagination_info = scim_pagination_info(query.count)
        page_of_results = query
                            .order(id: :asc)
                            .offset(pagination_info.offset)
                            .limit(pagination_info.limit)
                            .to_a

        super(pagination_info, page_of_results) do |record|
          record.to_scim(
            location: url_for(action: :show, id: record.id),
            include_attributes:
          )
        end
      end

      def show
        super do |record_id|
          record = storage_scope.find(record_id)
          record.to_scim(
            location: url_for(action: :show, id: record_id),
            include_attributes:
          )
        end
      end

      private

      def include_attributes
        first_level_attrs = storage_class.scim_attributes_map.keys.map(&:to_s)
        second_level_attrs =
          storage_class
            .scim_attributes_map
            .find_all { |_, v| v.is_a? Hash }
            .flat_map { |parent, childs| childs.map { |child, _| "#{parent}.#{child}" } }
        all_possible_attributes = (first_level_attrs + second_level_attrs)

        excluded_attributes = params.fetch(:excludedAttributes, "").split(",")
        excluded_parents = excluded_attributes.filter_map { |attr| attr.split(".")[-2] }

        all_possible_attributes - excluded_attributes - excluded_parents
      end

      def raise_result_errors_for_scim(result)
        result.on_failure do |result|
          if uniqueness_error?(result)
            raise Scimitar::ErrorResponse.new(
              status: 409,
              scimType: "uniqueness",
              detail: "Operation failed due to a uniqueness constraint: #{result.message}"
            )
          elsif authorization_error?(result)
            raise Scimitar::ErrorResponse.new(
              status: 403,
              detail: "Action forbidden: insufficient permissions."
            )
          else
            raise result.message
          end
        end
      end

      def uniqueness_error?(result)
        result.errors.any? { |e| e.type == :taken }
      end

      def authorization_error?(result)
        result.errors.any? { |e| e.type == :error_unauthorized }
      end
    end
  end
end
