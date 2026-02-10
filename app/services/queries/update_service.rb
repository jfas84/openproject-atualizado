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

# module Queries
#   class UpdateService < ::BaseServices::Update
#     def call(params)
#       # 1. Executa a atualização normal do OpenProject primeiro
#       # Isso garante que o nome seja salvo no banco e validado
#       result = super(params)

#       # 2. Se salvou com sucesso, executamos nossa mágica
#       if result.success?
#         # Verifica se o nome foi alterado neste request
#         new_name = params[:name]

#         if new_name.present?
#           Rails.logger.warn "🔥 [QUERY SYNC] Nome da lista alterado para: #{new_name}"
          
#           # O 'model' aqui é a Query. Ela pertence a um projeto.
#           project = model.project

#           # Chama o nosso serviço de sincronização
#           sync_result = ::Boards::ListStatusSyncService.new(user: user)
#                                                        .call(name: new_name, project: project)
          
#           if sync_result.success?
#             Rails.logger.warn "✅ [QUERY SYNC] Status sincronizado com sucesso!"
            
#             # (Opcional) Se você quiser garantir que a Query agora filtre por esse novo status:
#             # update_query_filter(model, sync_result.result) 
#           else
#             Rails.logger.error "❌ [QUERY SYNC] Falha ao criar status."
#           end
#         end
#       end

#       # Retorna o resultado original para não quebrar o fluxo do OpenProject
#       result
#     end
#   end
# end
# module Queries
#   class UpdateService < ::BaseServices::Update
#     def call(params)
#       # 1. CAPTURA O NOME ANTIGO ANTES DE ATUALIZAR
#       # O 'model' ainda tem os dados antigos aqui
#       old_name = model.name 

#       # 2. Executa a atualização normal do OpenProject
#       result = super(params)

#       # 3. Se salvou com sucesso, executamos nossa mágica
#       if result.success?
#         # Verifica se o nome foi alterado neste request
#         new_name = params[:name]

#         # Só faz sentido rodar se o nome mudou E se não for vazio
#         if new_name.present? && new_name != old_name
#           Rails.logger.warn "🔥 [QUERY SYNC] Renomeando lista: '#{old_name}' -> '#{new_name}'"
          
#           project = model.project

#           # Chama o serviço passando AMBOS os nomes (Antigo e Novo)
#           sync_result = ::Boards::ListStatusSyncService.new(user: user).call(
#             new_name: new_name, 
#             old_name: old_name, 
#             project: project
#           )
          
#           if sync_result.success?
#             Rails.logger.warn "✅ [QUERY SYNC] Status atualizado/criado com sucesso!"
#           else
#             Rails.logger.error "❌ [QUERY SYNC] Falha na sincronização do status."
#           end
#         end
#       end

#       result
#     end
#   end
# end

module Queries
  class UpdateService < ::BaseServices::Update
    def call(params)
      old_name = model.name 
      result = super(params)

      if result.success?
        new_name = params[:name]
        
        if new_name.present? && new_name != old_name
          # ATUALIZAÇÃO: Passando 'query: model'
          ::Boards::ListStatusSyncService.new(user: user).call(
            new_name: new_name, 
            old_name: old_name, 
            project: model.project,
            query: model # <--- OBRIGATÓRIO PARA O BIND FUNCIONAR
          )
        end
      end
      result
    end
  end
end