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
import LogUtils from './LogUtils';

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
    if(!this.context) {
      LogUtils.error("LIUZIWEI", 'getContext context null');
    }
    return this.context;
  }

  getWantParams(): WantParams {
    if(!this.wantParams) {
      LogUtils.error("LIUZIWEI", 'getWantParams wantParams null');
    }
    return this.wantParams;
  }

  getSession(): UIExtensionContentSession {
    if(!this.session) {
      LogUtils.error("LIUZIWEI", 'getSession session null');
    }
    return this.session;
  }

  getWidgetContextId(): number{
    return this.widgetContextId;
  }

  setContext(context: common.UIExtensionContext): void {
    LogUtils.error("LIUZIWEI", 'setContext');
    this.context = context;
    if (this.context){
      LogUtils.error("LIUZIWEI", 'setContext is not null');
    }
  }

  setWantParams(wantParams: WantParams): void {
    LogUtils.error("LIUZIWEI", 'setWantParams');
    this.wantParams = wantParams;
    if (this.wantParams) {
      LogUtils.error("LIUZIWEI", 'setWantParams is not null');
    }
  }

  setSession(session: UIExtensionContentSession): void {
    LogUtils.error("LIUZIWEI", 'setSession');
    this.session = session;
    if (this.session) {
      LogUtils.error("LIUZIWEI", 'setSession is not null');
    }
  }

  setWidgetContextId(widgetContextId: number): void{
    this.widgetContextId = widgetContextId;
  }
}
