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

# Código anterior:

# class Views::CreateService < BaseServices::Create; end

# Atualização em 23/01/2026 para criar um Dashboard Geral que veja todos os projetos e subprojetos


class Views::CreateService < BaseServices::Create
  def call
    Rails.logger.info "🎯 [MACRO BOARD] CRIANDO UM BOARD GERAL"

    # 1. Executa a criação padrão do OpenProject (super)
    result = super

    # 2. Se a criação foi um sucesso, rodamos a automação do Board Geral
    if result.success?
      view = result.result # O objeto criado (Board/View) fica aqui
      
      # Verificamos se o nome é 'Geral'
      if view.respond_to?(:name) && view.name&.downcase == "geral"
        Rails.logger.info "🎯 [MACRO BOARD] Detectada criação de Board 'Geral'. Iniciando automação..."
        
        # Chama o serviço que criamos anteriormente
        # O 'user' já está disponível nesta classe por herança
        ::Boards::MacroBuilderService.new(user: user).call(view)
      end
    end

    # Retorna o resultado original para não quebrar o fluxo da API
    result
  end
end
