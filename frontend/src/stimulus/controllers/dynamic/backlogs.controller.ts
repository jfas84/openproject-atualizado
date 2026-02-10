//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import { FrameElement, TurboVisitEvent } from '@hotwired/turbo';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { filter, Subscription } from 'rxjs';
import StoryController from './backlogs/story.controller';

export default class BacklogsController extends Controller<HTMLElement> {
  static outlets = ['backlogs--story'];
  declare backlogsStoryOutlets:StoryController[];

  static values = {
    listUrl: String,
  };

  declare listUrlValue:string;

  private abortController:AbortController|null = null;
  private service:HalEventsService|null = null;
  private subscription:Subscription|null = null;

  // eslint-disable-next-line @typescript-eslint/no-misused-promises
  async connect() {
    this.abortController = new AbortController();
    const { signal } = this.abortController;

    document.addEventListener('turbo:visit', this.updateSelection, { signal });

    const { services: { halEvents } } = await window.OpenProject.getPluginContext();

    this.service = halEvents;
    this.subscription = this.service.aggregated$('WorkPackage')
      .pipe(filter((events) => events.some((event) => event.eventType === 'updated')))
      .subscribe(() => { this.refreshList(); });
  }

  disconnect() {
    this.subscription?.unsubscribe();
    this.subscription = null;
    this.service = null;

    this.abortController?.abort();
    this.abortController = null;
  }

  backlogsStoryOutletConnected(outlet:StoryController) {
    const selectedId = this.getSelectedIdFromPathname(window.location.pathname);
    if (selectedId !== null && outlet.idValue === selectedId) {
      outlet.markAsSelected();
    }
  }

  private updateSelection = (event:TurboVisitEvent) => {
    const url = new URL(event.detail.url, window.location.origin);
    const selectedId = this.getSelectedIdFromPathname(url.pathname);

    this.backlogsStoryOutlets.forEach((story) => {
      if (selectedId !== null && story.idValue === selectedId) {
        story.markAsSelected(event);
      } else {
        story.unmarkAsSelected(event);
      }
    });
  };

  private getSelectedIdFromPathname(pathname:string):number|null {
    const match = /\/details\/(\d+)/.exec(pathname);
    return match ? Number(match[1]) : null;
  }

  private refreshList() {
    this.listElement.src = this.listUrlValue;
  }

  private get listElement() {
    return this.element.querySelector<FrameElement>('#backlogs_container')!;
  }
}
