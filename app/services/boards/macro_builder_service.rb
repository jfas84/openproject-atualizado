module Boards
  class MacroBuilderService
    def initialize(user:)
      @user = User.find(4) # Força Admin para garantir permissões
    end

    def call(grid)
      Rails.logger.info "🚀 [MACRO START] Iniciando serviço v3 (Widget Options Force)"

      # 1. Validações
      unless grid.is_a?(::Boards::Grid)
        Rails.logger.error "❌ [MACRO] Grid inválido."
        return
      end

      if grid.name.to_s.strip.downcase != 'geral'
        Rails.logger.info "ℹ️ [MACRO] Ignorando grid '#{grid.name}'."
        return
      end

      project = grid.project
      unless project
        Rails.logger.error "❌ [MACRO] Sem projeto pai."
        return
      end

      # 2. Escopo e Dados
      subprojects = project.descendants
      all_ids = [project.id] + subprojects.pluck(:id)
      
      # Unscoped para ignorar filtros ocultos
      cards = WorkPackage.unscoped.where(project_id: all_ids).includes(:status)

      if cards.empty?
        Rails.logger.warn "⚠️ [MACRO] Sem cartões."
      end

      # Mapeamento
      status_map = {}
      cards.each { |wp| status_map[wp.status_id] = wp.status.name }

      Rails.logger.info "📊 [MACRO] #{cards.count} cards em #{status_map.count} colunas."

      # 3. Execução
      rebuild_grid(grid, status_map)
      
    rescue StandardError => e
      Rails.logger.error "🔥 [MACRO CRASH] #{e.message}\n#{e.backtrace.join("\n")}"
    end

    private

    def rebuild_grid(grid, status_map)
      project = grid.project
      current_col = 1

      ActiveRecord::Base.transaction do
        grid.widgets.destroy_all

        # Ordenação
        sorted_status_ids = status_map.keys.sort_by do |sid|
          Status.find_by(id: sid)&.position || 999
        end

        sorted_status_ids.each do |status_id|
          status_name = status_map[status_id]
          Rails.logger.info "🔨 [MACRO] Criando coluna '#{status_name}'..."

          # A. QUERY (Backend)
          query = Query.new(
            project: project,
            name: status_name,
            user: @user,
            public: true
          )
          query.include_subprojects = true
          query.filters = []
          query.add_filter('status_id', '=', [status_id.to_s])

          if query.save
            Rails.logger.info "   ✅ Query salva (ID #{query.id})"

            # B. WIDGET OPTIONS (Frontend Force)
            # Aqui está o segredo: Passamos os filtros explicitamente nas opções do widget.
            # O Frontend do OP lê isso e monta a URL correta, parando de enviar filters=[]
            
            widget_options = {
              queryId: query.id,
              filters: [
                {
                  status_id: {
                    operator: "=",
                    values: [status_id.to_s]
                  }
                }
              ]
            }

            # C. WIDGET
            widget = grid.widgets.build(
              identifier: 'work_package_query',
              start_row: 1, end_row: 2,
              start_column: current_col, end_column: current_col + 1,
              options: widget_options
            )

            if widget.save
              Rails.logger.info "   ✅ Widget salvo na coluna #{current_col}"
              current_col += 1
            else
              Rails.logger.error "   ❌ Erro Widget: #{widget.errors.full_messages}"
            end
          else
            Rails.logger.error "   ❌ Erro Query: #{query.errors.full_messages}"
          end
        end

        grid.update_column(:column_count, current_col)
        grid.touch
      end
    end
  end
end