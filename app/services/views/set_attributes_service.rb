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

# 15/01/2026
# Código anterior a implementação do serviço de sincronização de status do quadro.
# Removido para adicionar a lógica de sincronização de status ao criar/atualizar views.
# module Views
#   class SetAttributesService < ::BaseServices::SetAttributes; end
# end

# module Views
#   class SetAttributesService < ::BaseServices::SetAttributes
#     def transform_params
#       super
#       # Aqui interceptamos a criação de novas colunas
#       # Verificamos se há novos widgets de query sendo adicionados
#       if model.is_a?(View) && params[:widgets]
#         params[:widgets].each do |widget_params|
#           # No Basic Board, as colunas são widgets do tipo 'query'
#           if widget_params[:options] && widget_params[:options][:name]
#             list_name = widget_params[:options][:name]
#             # Chama o nosso novo serviço
#             ::Boards::ListStatusSyncService.new(user: user)
#                                          .call(name: list_name, project: model.project)
#           end
#         end
#       end
#     end
#   end
# end


module Views
  class SetAttributesService < ::BaseServices::SetAttributes
    def transform_params
      # --- DEBUG INICIAL ---
      Rails.logger.warn "🔥 [DEBUG BOARD] O SetAttributesService FOI CHAMADO!"
      
      # Verifica se 'widgets' veio no payload (como string ou symbol)
      widgets_data = params[:widgets] || params['widgets']

      if widgets_data
        Rails.logger.warn "🔥 [DEBUG BOARD] Payload contém 'widgets'. Quantidade: #{widgets_data.size}"
        Rails.logger.warn "🔥 [DEBUG BOARD] Conteúdo: #{widgets_data.inspect}"
      else
        Rails.logger.warn "⚠️ [DEBUG BOARD] O serviço rodou, mas NÃO encontrou a chave 'widgets' nos params."
        Rails.logger.warn "⚠️ [DEBUG BOARD] Params recebidos: #{params.keys.inspect}"
      end

      # 1. Remove para evitar erro no super (Mantendo sua lógica correta)
      params.delete(:widgets)
      params.delete('widgets')

      super 

      # 2. Executa a sincronização
      # Adicionamos logs internos para saber se entrou no IF
      if widgets_data && model.respond_to?(:query) && model.query
        Rails.logger.warn "🔥 [DEBUG BOARD] Entrou na lógica de sincronização."
        
        widgets_data.each do |widget_patch|
          options = widget_patch[:options] || widget_patch['options']
          new_name = options ? (options[:name] || options['name']) : nil
          
          if new_name.present?
            Rails.logger.warn "🔥 [DEBUG BOARD] Tentando criar status para: '#{new_name}'"
            
            # Chama o serviço
            begin
              # ::Boards::ListStatusSyncService.new(user: user)
              #                                .call(name: new_name, project: model.query.project)
              ::Boards::ListStatusSyncService.new(user: user).call(
              name: new_name, 
              project: model.query.project,
              query: model.query # <--- OBRIGATÓRIO
            )
              Rails.logger.warn "✅ [DEBUG BOARD] Serviço de Sync chamado com sucesso."
            rescue => e
              Rails.logger.error "❌ [DEBUG BOARD] Erro ao chamar SyncService: #{e.message}"
            end
          end
        end
      else
        Rails.logger.warn "⚠️ [DEBUG BOARD] Não entrou no IF principal (Model sem query ou sem widgets)."
        Rails.logger.warn "   > Widgets data present? #{!!widgets_data}"
        Rails.logger.warn "   > Model respond to query? #{model.respond_to?(:query)}"
        Rails.logger.warn "   > Model has query? #{model.respond_to?(:query) && !!model.query}"
      end
    end
  end
end