/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import common from '@ohos.app.ability.common';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { WantParams } from '../vm/Constants';

export class GlobalObject {
  private constructor() {};
  private static instance: GlobalObject;
  private context: common.UIExtensionContext;
  private wantParams: WantParams;
  private session: UIExtensionContentSession;
  private widgetContextId: number;

  public static getObject(): GlobalObject {
    if (!GlobalObject.instance) {
      GlobalObject.instance = new GlobalObject();
    }
    return GlobalObject.instance;
  }

  getContext(): common.UIExtensionContext {
    return this.context;
  }

  getWantParams(): WantParams {
    return this.wantParams;
  }

  getSession(): UIExtensionContentSession {
    return this.session;
  }

  getWidgetContextId(): number{
    return this.widgetContextId;
  }

  setContext(context: common.UIExtensionContext): void {
    this.context = context;
  }

  setWantParams(wantParams: WantParams): void {
    this.wantParams = wantParams;
  }

  setSession(session: UIExtensionContentSession): void {
    this.session = session;
  }

  setWidgetContextId(widgetContextId: number): void{
    this.widgetContextId = widgetContextId;
  }
}
