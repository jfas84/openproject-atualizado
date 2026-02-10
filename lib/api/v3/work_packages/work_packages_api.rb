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

require "api/v3/work_packages/work_package_representer"

module API
  module V3
    module WorkPackages
      class WorkPackagesAPI < ::API::OpenProjectAPI
        resources :work_packages do
          helpers ::API::V3::WorkPackages::WorkPackagesSharedHelpers

          # The endpoint needs to be mounted before the GET :work_packages/:id.
          # Otherwise, the matcher for the :id also seems to match available_projects.
          # This is also true when the :id param is declared to be of type: Integer.
          mount ::API::V3::WorkPackages::AvailableProjectsOnCreateAPI
          mount ::API::V3::WorkPackages::Schema::WorkPackageSchemasAPI

          get do
            authorize_in_any_work_package(:view_work_packages)

            call = raise_invalid_query_on_service_failure do
              WorkPackageCollectionFromQueryParamsService
                .new(current_user)
                .call(params)
            end

            call.result
          end

          post(&::API::V3::Utilities::Endpoints::Create.new(model: WorkPackage,
                                                            parse_service: WorkPackages::ParseParamsService,
                                                            params_modifier: ->(attributes) {
                                                              attributes[:send_notifications] = notify_according_to_params
                                                              attributes
                                                            })
                                                       .mount)

          route_param :id, type: Integer, desc: "Work package ID" do
            helpers WorkPackagesSharedHelpers

            helpers do
              attr_reader :work_package
            end

            after_validation do
              @work_package = WorkPackage.find(declared_params[:id])

              authorize_in_work_package(:view_work_packages, work_package: @work_package) do
                raise API::Errors::NotFound.new model: :work_package
              end
            end

            get &API::V3::WorkPackages::ShowEndPoint.new(model: WorkPackage).mount

            patch &::API::V3::WorkPackages::UpdateEndPoint.new(model: WorkPackage,
                                                               parse_service: ::API::V3::WorkPackages::ParseParamsService,
                                                               params_modifier: ->(attributes) {
                                                                attributes[:send_notifications] = notify_according_to_params
                                                                
                                                                status_id = attributes[:status_id]

                                                                if status_id.present?
                                                                  wp_id = params[:id]
                                                                  wp = WorkPackage.find_by(id: wp_id)

                                                                  if wp
                                                                    new_status = Status.find_by(id: status_id)
                                                                    
                                                                    if new_status
                                                                      # Busca a Query (coluna) alvo
                                                                      target_query = Query.where(project_id: wp.project_id, name: new_status.name).first
                                                                      
                                                                      if target_query
                                                                        Rails.logger.info "🔄 [STATUS->BOARD] WP ##{wp.id} movendo para '#{target_query.name}'..."
                                                                        
                                                                        # --- O PULO DO GATO ESTÁ AQUI ---
                                                                        # 1. Remove o cartão de QUALQUER outra lista/coluna onde ele esteja registrado.
                                                                        # Isso garante que ele "saia" da coluna antiga.
                                                                        OrderedWorkPackage.where(work_package_id: wp.id).delete_all

                                                                        # 2. Cria o registro na NOVA coluna.
                                                                        # Como limpamos tudo acima, o find_or_initialize_by criará um novo registro limpo.
                                                                        order_record = target_query.ordered_work_packages.find_or_initialize_by(work_package_id: wp.id)
                                                                        order_record.position = 0 
                                                                        order_record.save
                                                                        
                                                                        Rails.logger.info "✅ [STATUS->BOARD] Cartão movido com sucesso e removido da coluna anterior."
                                                                      end
                                                                    end
                                                                  end
                                                                end

                                                                attributes
                                                              })
                                                          .mount

            delete &::API::V3::Utilities::Endpoints::Delete.new(model: WorkPackage)
                                                           .mount

            mount ::API::V3::WorkPackages::WatchersAPI
            mount ::API::V3::Activities::ActivitiesByWorkPackageAPI
            mount ::API::V3::Attachments::AttachmentsByWorkPackageAPI
            mount ::API::V3::Repositories::RevisionsByWorkPackageAPI
            mount ::API::V3::WorkPackages::UpdateFormAPI
            mount ::API::V3::WorkPackages::AvailableAssigneesAPI
            mount ::API::V3::WorkPackages::AvailableProjectsOnEditAPI
            mount ::API::V3::WorkPackages::AvailableRelationCandidatesAPI
            mount ::API::V3::WorkPackages::WorkPackageRelationsAPI
            mount ::API::V3::Reminders::RemindersByWorkPackageAPI
            mount ::API::V3::EmojiReactions::EmojiReactionsByWorkPackageCommentsAPI
          end

          mount ::API::V3::WorkPackages::CreateFormAPI
        end
      end
    end
  end
end
