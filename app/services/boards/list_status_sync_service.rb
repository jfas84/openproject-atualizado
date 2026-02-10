# Implementação do serviço para sincronizar o status do quadro 15/01/2026.
# app/services/boards/list_status_sync_service.rb
# frozen_string_literal: true

# frozen_string_literal: true

# frozen_string_literal: true

# module Boards
#   class ListStatusSyncService < ::BaseServices::Create
#     def call(name:, project:)
#       # 1. Localiza ou cria o Status
#       status = find_or_create_status(name)

#       # 2. Configura o Workflow usando Role.all
#       setup_workflow_for_project(status, project)

#       ServiceResult.success(result: status)
#     rescue StandardError => e
#       ServiceResult.failure(result: nil, errors: [e.message])
#     end

#     private

#     def find_or_create_status(name)
#       # Segue as regras de unicidade e cor do seu modelo
#       Status.find_or_create_by!(name: name) do |s|
#         s.color = Color.first if Color.any?
#       end
#     end

#     def setup_workflow_for_project(status, project)
#       # Roles são globais, Types são associados ao projeto
#       roles = Role.all 
#       types = project.types
#       all_statuses = Status.all

#       Workflow.transaction do
#         types.each do |type|
#           roles.each do |role|
#             all_statuses.each do |old_status|
#               next if old_status.id == status.id
#               # Cria a transição: de qualquer estado para o novo estado da lista
#               Workflow.find_or_create_by!(
#                 role_id: role.id,
#                 type_id: type.id,
#                 old_status_id: old_status.id,
#                 new_status_id: status.id
#               )
#             end
#           end
#         end
#       end
#     end
#   end
# end

# module Boards
#   class ListStatusSyncService < ::BaseServices::Create
#     # Recebe new_name e old_name
#     def call(new_name:, old_name: nil, project:)
      
#       # LÓGICA INTELIGENTE DE STATUS
#       status = manage_status(new_name, old_name)

#       # Configura o Workflow (igual ao anterior)
#       setup_workflow_for_project(status, project)

#       ServiceResult.success(result: status)
#     rescue StandardError => e
#       ServiceResult.failure(result: nil, errors: [e.message])
#     end

#     private

#     def manage_status(new_name, old_name)
#       # 1. Verifica se já existe um status com o NOVO nome (para evitar duplicidade)
#       target_status_exists = Status.find_by(name: new_name)

#       # 2. Verifica se existe o status ANTIGO (o que vamos renomear)
#       old_status = Status.find_by(name: old_name) if old_name.present?

#       if old_status && !target_status_exists
#         # CENÁRIO A: Existe o antigo e o nome novo está livre.
#         # AÇÃO: Renomear o status antigo.
#         Rails.logger.warn "🔄 [SYNC] Renomeando Status ID #{old_status.id}: '#{old_name}' para '#{new_name}'"
#         old_status.name = new_name
#         old_status.save!
#         return old_status

#       elsif target_status_exists
#         # CENÁRIO B: O nome novo já está sendo usado por outro status.
#         # AÇÃO: Não podemos renomear o antigo (daria erro de nome duplicado). 
#         # Usamos o status que já existe com esse nome.
#         Rails.logger.warn "⚠️ [SYNC] O status '#{new_name}' já existe. Vinculando a ele."
#         return target_status_exists

#       else
#         # CENÁRIO C: Não existe nem o antigo, nem o novo.
#         # AÇÃO: Criar um status novo do zero.
#         Rails.logger.warn "✨ [SYNC] Criando novo status: '#{new_name}'"
#         return create_new_status(new_name)
#       end
#     end

#     def create_new_status(name)
#       Status.create!(name: name) do |s|
#         # Define uma cor padrão se houver cores no sistema
#         s.color = Color.first if Color.any?
#       end
#     end

#     def setup_workflow_for_project(status, project)
#       roles = Role.all 
#       types = project.types
#       all_statuses = Status.all

#       Workflow.transaction do
#         types.each do |type|
#           roles.each do |role|
#             all_statuses.each do |other_status|
#               next if other_status.id == status.id
              
#               # Cria transição DE -> PARA
#               Workflow.find_or_create_by!(
#                 role_id: role.id,
#                 type_id: type.id,
#                 old_status_id: other_status.id,
#                 new_status_id: status.id
#               )

#               # Cria transição PARA -> DE (Bidirecional para poder voltar o card)
#               Workflow.find_or_create_by!(
#                 role_id: role.id,
#                 type_id: type.id,
#                 old_status_id: status.id,
#                 new_status_id: other_status.id
#               )
#             end
#           end
#         end
#       end
#     end
#   end
# end

module Boards
  class ListStatusSyncService < ::BaseServices::Create
    # Adicionamos o argumento opcional 'query'
    def call(new_name:, old_name: nil, project:, query: nil)
      
      # 1. Gerencia o Status (Cria ou Renomeia) - Sua lógica atual
      status = manage_status(new_name, old_name)

      # 2. Configura Workflow
      setup_workflow_for_project(status, project)

      # 3. (NOVO) Aplica o filtro na Query para criar o vínculo mágico
      if query
        apply_status_filter(query, status)
      end

      ServiceResult.success(result: status)
    rescue StandardError => e
      Rails.logger.error "❌ [SYNC ERROR] #{e.message}"
      ServiceResult.failure(result: nil, errors: [e.message])
    end

    private

    def manage_status(new_name, old_name)
      target_status_exists = Status.find_by(name: new_name)
      old_status = Status.find_by(name: old_name) if old_name.present?

      if old_status && !target_status_exists
        # Renomeia
        old_status.update!(name: new_name)
        return old_status
      elsif target_status_exists
        # Usa existente
        return target_status_exists
      else
        # Cria novo
        return create_new_status(new_name)
      end
    end

    def create_new_status(name)
      Status.create!(name: name) do |s|
        s.color = Color.first if Color.any?
      end
    end

    # --- A MÁGICA ACONTECE AQUI ---
    def apply_status_filter(query, status)
      # Adiciona/Atualiza o filtro de status na Query da lista
      current_filters = query.filters || []
      
      # Remove filtros de status antigos para evitar conflito
      current_filters.reject! { |f| f.filter == :status_id }

      # Adiciona o novo filtro apontando para o Status ID correto
      new_filter = Queries::Filters::Shared::StatusFilter.new(query)
      new_filter.operator = '='
      new_filter.values = [status.id.to_s]

      # Salva na query
      query.filters = current_filters + [new_filter]
      
      # Importante: Salvar sem validação completa para evitar loops de callbacks
      query.save(validate: false)
      
      Rails.logger.warn "🔗 [BIND] Lista '#{query.name}' vinculada ao Status '#{status.name}' (ID: #{status.id})"
    end

    def setup_workflow_for_project(status, project)
      # Mantive sua lógica de workflow aqui (simplificada para o exemplo)
      # Ela é importante para permitir o movimento
      roles = Role.all 
      types = project.types
      all_statuses = Status.all

      Workflow.transaction do
        types.each do |type|
          roles.each do |role|
            all_statuses.each do |other|
              next if other.id == status.id
              Workflow.find_or_create_by!(role: role, type: type, old_status: other, new_status: status)
              Workflow.find_or_create_by!(role: role, type: type, old_status: status, new_status: other)
            end
          end
        end
      end
    end
  end
end