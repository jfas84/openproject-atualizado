/*
 * -- copyright
 * openproject is an open source project management software.
 * copyright (c) the openproject gmbh
 *
 * this program is free software; you can redistribute it and/or
 * modify it under the terms of the gnu general public license version 3.
 *
 * openproject is a fork of chiliproject, which is a fork of redmine. the copyright follows:
 * copyright (c) 2006-2013 jean-philippe lang
 * copyright (c) 2010-2013 the chiliproject team
 *
 * this program is free software; you can redistribute it and/or
 * modify it under the terms of the gnu general public license
 * as published by the free software foundation; either version 2
 * of the license, or (at your option) any later version.
 *
 * this program is distributed in the hope that it will be useful,
 * but without any warranty; without even the implied warranty of
 * merchantability or fitness for a particular purpose.  see the
 * gnu general public license for more details.
 *
 * you should have received a copy of the gnu general public license
 * along with this program; if not, write to the free software
 * foundation, inc., 51 franklin street, fifth floor, boston, ma  02110-1301, usa.
 *
 * see copyright and license files for more details.
 * ++
 */

import { HocuspocusProvider } from '@hocuspocus/provider';
import { Controller } from '@hotwired/stimulus';
import { LiveCollaborationManager } from 'core-stimulus/helpers/live-collaboration-helpers';
import { PROVIDER_AUTH_ERROR_EVENT, ProviderAuthErrorKind, TokenRefreshService } from 'core-stimulus/services/documents/token-refresh.service';
import type { Doc } from 'yjs';
import * as Y from 'yjs';

export default class extends Controller {
  static values = {
    hocuspocusUrl: String,
    tokenPayload: String,
    documentName: String,
    tokenExpiresInSeconds: Number,
    refreshUrl: String,
  };

  declare readonly hocuspocusUrlValue:string;
  declare readonly tokenPayloadValue:string;
  declare readonly documentNameValue:string;
  declare readonly tokenExpiresInSecondsValue:number;
  declare readonly refreshUrlValue:string;

  private tokenRefreshService:TokenRefreshService | null = null;
  private currentToken = '';
  private canUseCachedToken = true;

  // On initial load, the DOM token is fresh. On reconnection (e.g., after server restart),
  // we must fetch a fresh token since the cached one may be expired.
  private getToken = async ():Promise<string> => {
    if (this.canUseCachedToken) {
      this.canUseCachedToken = false;
      return this.currentToken;
    }
    const data = await TokenRefreshService.fetchToken(this.refreshUrlValue);
    this.currentToken = data.encrypted_token;
    return this.currentToken;
  };

  connect():void {
    this.currentToken = this.tokenPayloadValue;

    const ydoc:Doc = new Y.Doc();
    const provider = new HocuspocusProvider({
      url: this.hocuspocusUrlValue,
      name: this.documentNameValue,
      token: this.getToken,
      document: ydoc,
      onAuthenticationFailed: () => {
        document.dispatchEvent(new CustomEvent(PROVIDER_AUTH_ERROR_EVENT, {
          detail: { kind: 'authentication' as ProviderAuthErrorKind, message: 'Authentication failed' },
        }));
      },
    });

    LiveCollaborationManager.initializeYjsProvider(provider, ydoc);

    if (this.refreshUrlValue && this.tokenExpiresInSecondsValue) {
      // Destroy any existing service to prevent duplicate timers if connect() is called multiple times
      this.tokenRefreshService?.destroy();
      this.tokenRefreshService = new TokenRefreshService(
        provider,
        this.refreshUrlValue,
        (newToken) => {
          this.currentToken = newToken;
          this.canUseCachedToken = true;
        },
      );
      this.tokenRefreshService.scheduleRefresh(this.tokenExpiresInSecondsValue);
    }
  }

  disconnect():void {
    this.tokenRefreshService?.destroy();
    this.tokenRefreshService = null;
    LiveCollaborationManager.destroy();
  }
}
