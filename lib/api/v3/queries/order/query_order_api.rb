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

# module API
#   module V3
#     module Queries
#       module Order
#         class QueryOrderAPI < ::API::OpenProjectAPI
#           resource :order do
#             helpers do
#               ##
#               # Remove the order for the given work package
#               def remove_order(wp_id)
#                 @query.ordered_work_packages.where(work_package_id: wp_id).delete_all
#               end

#               def upsert_order(wp_id, position)
#                 record = @query
#                   .ordered_work_packages
#                   .find_or_initialize_by(work_package_id: wp_id)

#                 upsert_attributes = record.attributes.merge(position:).compact
#                 OrderedWorkPackage.upsert(upsert_attributes)
#               end
#             end

#             get do
#               sql = <<~SQL.squish
#                 SELECT json_object_agg(work_package_id, position)
#                 FROM (
#                   SELECT work_package_id, position FROM #{OrderedWorkPackage.table_name} WHERE query_id = :query_id
#                 ) sub;
#               SQL

#               sql_query = ::OpenProject::SqlSanitization
#                 .sanitize sql, query_id: @query.id

#               ActiveRecord::Base.connection
#                 .exec_query(sql_query)
#                 .rows
#                 .first # first row
#                 .first || {}.to_json # first column (json object or null)
#             end

#             params do
#               optional :delta, type: Hash
#             end
#             patch do
#               authorize_by_policy(:update) do
#                 raise API::Errors::NotFound
#               end

#               params[:delta].each do |work_package_id, new_position|
#                 if new_position == -1
#                   remove_order(work_package_id)
#                 else
#                   upsert_order(work_package_id, new_position)
#                 end
#               end

#               @query.touch
#               { t: ::API::V3::Utilities::DateTimeFormatter.format_datetime(@query.updated_at) }
#             end
#           end
#         end
#       end
#     end
#   end
# end
module API
  module V3
    module Queries
      module Order
        class QueryOrderAPI < ::API::OpenProjectAPI
          resource :order do
            helpers do
              ##
              # Remove the order for the given work package
              def remove_order(wp_id)
                @query.ordered_work_packages.where(work_package_id: wp_id).delete_all
              end

              def upsert_order(wp_id, position)
                record = @query
                  .ordered_work_packages
                  .find_or_initialize_by(work_package_id: wp_id)

                upsert_attributes = record.attributes.merge(position:).compact
                OrderedWorkPackage.upsert(upsert_attributes)
              end

              # --- NOVA FUNÇÃO DE SINCRONIZAÇÃO DE STATUS ---
              def update_status_if_needed(wp_id)
                # 1. Pega o nome da lista atual (@query é a lista)
                list_name = @query.name
                
                # 2. Busca se existe um status com esse nome
                target_status = Status.find_by(name: list_name)
                
                # Se não existir status com esse nome, não faz nada
                return unless target_status

                # 3. Busca o WorkPackage
                work_package = WorkPackage.find_by(id: wp_id)
                return unless work_package

                # 4. Só atualiza se o status for diferente (evita loops e processamento inútil)
                if work_package.status_id != target_status.id
                  Rails.logger.info "🔄 [DRAG API] Movendo WP ##{wp_id} para lista '#{list_name}'. Atualizando status..."
                  
                  # Usa o serviço oficial para garantir permissões, histórico e notificações
                  service = ::WorkPackages::UpdateService.new(
                    user: current_user, # O usuário logado que fez o movimento
                    model: work_package
                  )
                  
                  result = service.call(status_id: target_status.id)
                  
                  if result.failure?
                    Rails.logger.error "❌ [DRAG API] Falha ao atualizar status: #{result.errors.full_messages.join(', ')}"
                  else
                    Rails.logger.info "✅ [DRAG API] Status atualizado com sucesso!"
                  end
                end
              rescue => e
                Rails.logger.error "❌ [DRAG API ERROR] #{e.message}"
              end
              # ----------------------------------------------
            end

            get do
              sql = <<~SQL.squish
                SELECT json_object_agg(work_package_id, position)
                FROM (
                  SELECT work_package_id, position FROM #{OrderedWorkPackage.table_name} WHERE query_id = :query_id
                ) sub;
              SQL

              sql_query = ::OpenProject::SqlSanitization
                .sanitize sql, query_id: @query.id

              ActiveRecord::Base.connection
                .exec_query(sql_query)
                .rows
                .first # first row
                .first || {}.to_json # first column (json object or null)
            end

            params do
              optional :delta, type: Hash
            end
            patch do
              authorize_by_policy(:update) do
                raise API::Errors::NotFound
              end

              # Iterando sobre os cards movidos
              params[:delta].each do |work_package_id, new_position|
                if new_position == -1
                  remove_order(work_package_id)
                else
                  upsert_order(work_package_id, new_position)
                  
                  # --- AQUI É O PULO DO GATO ---
                  # Logo após salvar a posição na lista, atualizamos o status
                  update_status_if_needed(work_package_id)
                end
              end

              @query.touch
              { t: ::API::V3::Utilities::DateTimeFormatter.format_datetime(@query.updated_at) }
            end
          end
        end
      end
    end
  end
end