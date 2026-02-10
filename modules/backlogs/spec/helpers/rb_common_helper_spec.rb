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

require "rails_helper"

RSpec.describe RbCommonHelper do
  describe "#format_date_range" do
    let(:from) { Date.new(2025, 1, 6) }
    let(:to) { Date.new(2025, 1, 17) }

    context "with an Array" do
      it "renders both dates separated by an en-dash" do
        expected =
          "<time datetime=\"2025-01-06\">#{helper.format_date(from)}</time>" \
          "\u00A0\u2013\u00A0" \
          "<time datetime=\"2025-01-17\">#{helper.format_date(to)}</time>"

        expect(helper.format_date_range([from, to])).to be_html_eql(expected)
      end
    end

    context "when both dates are nil" do
      it "returns nil" do
        expect(helper.format_date_range([nil, nil])).to be_nil
      end
    end

    context "when only the start date is present" do
      it "renders the start date with an en-dash" do
        expected =
          "<time datetime=\"2025-01-06\">#{helper.format_date(from)}</time>" \
          "\u00A0\u2013\u00A0"

        expect(helper.format_date_range([from, nil])).to be_html_eql(expected)
      end
    end

    context "when only the end date is present" do
      it "renders the end date with an en-dash" do
        expected =
          "\u00A0\u2013\u00A0" \
          "<time datetime=\"2025-01-17\">#{helper.format_date(to)}</time>"

        expect(helper.format_date_range([nil, to])).to be_html_eql(expected)
      end
    end
  end
end
