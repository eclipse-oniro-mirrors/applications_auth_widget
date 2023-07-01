/*
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

import account_osAccount from '@ohos.account.osAccount';
import userAuth from '@ohos.userIAM.userAuth';
import util from '@ohos.util';
import CustomPSD from '../../common/components/CustomPSD'
import LogUtils from '../../common/utils/LogUtils';
import Constants from '../../common/vm/Constants';

const TAG = 'CustomPassword';

let pinAuthManager;
let pinData = '';

@Component
export default struct CustomPassword {
  @Link type: number;
  @Link themeType: number;
  @Link authType: Array<userAuth.UserAuthType>;
  @State @Watch('onFlagChange') controllerFlag: boolean = false;
  @State @Watch('onTextValueChange') textValue: string = '';
  controller: CustomDialogController;
  cancel: () => void;
  confirm: () => void;

  onFlagChange() {
    LogUtils.i(TAG, 'onFlagChange controllerFlag: ' + this.controllerFlag);
    if (this.controllerFlag) {
      globalThis.session?.terminateSelf();
    }
  }

  onTextValueChange() {
    LogUtils.i(TAG, 'aboutToAppear onTextValueChange this.textValue: ' + this.textValue);
    pinData = this.textValue;
  }

  aboutToAppear() {
    // register input
    try {
      LogUtils.i(TAG, 'aboutToAppear PINAuth start');
      pinAuthManager = new account_osAccount.PINAuth();
      LogUtils.i(TAG, 'aboutToAppear PINAuth pinAuthManager： ' + JSON.stringify(pinAuthManager));
      pinAuthManager.registerInputer({
        onGetData: (authSubType, callback) => {
          let textEncoder = new util.TextEncoder();
          let uint8PW = textEncoder.encode(pinData);
          LogUtils.i(TAG, `aboutToAppear PINAuth onGetData pinData：${this.textValue}, uint8PW:${uint8PW}`);
          callback.onSetData(authSubType, uint8PW);
        }
      });
    } catch (error) {
      LogUtils.e(TAG, 'aboutToAppear PINAuth catch error: ' + JSON.stringify(error));
    }
  }

  aboutToDisappear() {
    LogUtils.i(TAG, 'aboutToDisappear PINAuth unregisterInputer');
    pinAuthManager?.unregisterInputer?.()
  }

  build() {
    Stack() {
      Text().width(Constants.FULL_CONTAINER_WIDTH)
        .height(Constants.FULL_CONTAINER_WIDTH)
        .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
        .opacity(this.themeType === Constants.THEME_TYPE_WHITE ? 1 : 0.2)
      Column() {
        Flex({ direction: FlexDirection.Row }) {
          if (this.themeType === Constants.THEME_TYPE_WHITE) {
            Text('←')
              .borderRadius(8)
              .fontSize($r('app.float.title_size'))
              .width($r('app.float.title_size'))
              .height($r('app.float.title_size'))
              .margin({ left: $r("app.float.element_margin"), right: $r("app.float.element_margin"), top: '2vp' })
              .backgroundColor(Color.Transparent)
              .fontColor(Color.Black)
              .onClick(() => {
                globalThis.session?.terminateSelf();
              })
            Text($r('app.string.back'))
              .fontSize($r('app.float.title_size'))
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.Black)
              .textAlign(TextAlign.Center)
              .textOverflow({ overflow: TextOverflow.None })
          } else {
            Image($r('app.media.ic_white_cancel'))
              .width($r('app.float.title_size'))
              .height($r('app.float.title_size'))
              .margin({ left: $r("app.float.element_margin"), top: $r("app.float.element_margin") })
              .onClick(() => {
                globalThis.session?.terminateSelf();
              })
          }
        }

        GridRow({
          columns: 8,
          gutter: { x: 5, y: 10 },
          breakpoints: { value: ['360vp', '780vp'],
            reference: BreakpointsReference.WindowSize },
          direction: GridRowDirection.Row
        }) {
          GridCol({ span: { xs: 0, sm: 1, md: 1, lg: 1 } })
            .visibility(Visibility.Hidden)
          GridCol({
            span: { xs: 8, sm: 6, md: 6, lg: 6 },
          }) {
            CustomPSD({
              themeType: $themeType,
              type: $type,
              textValue: $textValue,
              controllerFlag: $controllerFlag,
              authType: $authType
            })
          }.margin({ left: 'auto', right: 'auto' })
        }

      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width(Constants.FULL_CONTAINER_WIDTH)
      .height(Constants.FULL_CONTAINER_WIDTH)
    }
    .width(Constants.FULL_CONTAINER_WIDTH)
    .height(Constants.FULL_CONTAINER_WIDTH)
    .backdropBlur(80)
  }
}