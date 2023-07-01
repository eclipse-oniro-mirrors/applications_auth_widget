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

import userAuth from '@ohos.userIAM.userAuth';
import window from '@ohos.window'
import LogUtils from '../common/utils/LogUtils';
import Constants from '../common/vm/Constants';
import CustomPassword from './components/CustomPassword';
import FaceAuth from './components/FaceAuth'
import FingerprintAuth from './components/FingerprintAuth'
import PasswordAuth from './components/PasswordAuth';

const TAG = 'Index';

let storage = LocalStorage.GetShared()

@Entry(storage)
@Component
struct Index {
  @State authType: Array<userAuth.UserAuthType> = [userAuth.UserAuthType.PIN]
  @State trust: string = '10000'
  @State control_title: string = '请输入密码'
  @State navigation_button_text: string = '确定'
  @State topHeight: number = 72;
  @State bottomHeight: number = 72;
  // dialog 0:six number 1:arbitrary character 2:arbitrary number
  // full 3:six number 4:arbitrary character 5:arbitrary number
  @State type: number = Constants.TYPE_DIALOG_ARBITRARY_NUMBER
  // background 1:white 2:Gaussian Blur
  @State themeType: number = Constants.THEME_TYPE_WHITE

  randomChallenge() {
    let arr = [];
    for (let index = 0; index <= 5; index++) {
      arr.push(Math.ceil(Math.random() * 9));
    }
    return new Uint8Array(arr);
  }

  onCancel() {
    LogUtils.d(TAG, 'Callback when the first button is clicked')
    globalThis.session?.terminateSelf();
    storage?.clear();
  }

  onAccept() {
    LogUtils.d(TAG, 'Callback when the second button is clicked')
  }

  existApp() {
    LogUtils.d(TAG, 'Click the callback in the blank area')
    globalThis.session?.terminateSelf();
    storage?.clear();
  }

  aboutToAppear() {
    LogUtils.d(TAG, 'aboutToAppear');
    if (globalThis.wantParams) {
      this.getParams();
      LogUtils.d(TAG, 'globalThis.wantParams' + JSON.stringify(globalThis.wantParams));
    } else {
      LogUtils.e(TAG, 'aboutToAppear wantParams null');
    }

    try {
      window.on('systemBarTintChange', (data) => {
        LogUtils.d(TAG, 'Succeeded in enabling the listener for window stage event changes. Data: ' +
        JSON.stringify(data));
       for (let i = 0; i < data.regionTint.length; i++) {
         let regionData = data.regionTint[i]
         if (regionData.type === window.WindowType.TYPE_STATUS_BAR) {
           this.topHeight  = px2vp(regionData.region.height)
           continue
         }
         if (regionData.type === window.WindowType.TYPE_NAVIGATION_BAR) {
           this.bottomHeight = px2vp(regionData.region.top)
           continue
         }
       }
      });
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to enable the listener for window stage event changes. Cause:' +
      JSON.stringify(exception));
    }
  }

  aboutToDisappear() {
    LogUtils.d(TAG, 'aboutToDisappear')
  }

  onPageShow() {
    LogUtils.i(TAG, 'onPageShow');
  }

  onPageHide() {
    LogUtils.i(TAG, 'onPageHide');
  }

  onBackPress() {
    LogUtils.i(TAG, 'onBackPress');
  }

  getParams() {
    LogUtils.i(TAG, 'getParams');
    this.authType = globalThis.wantParams.authParam?.authType;
    this.trust = globalThis.wantParams.authParam?.authTrustLevel;
    this.control_title = globalThis.wantParams.widgetParam?.title;
    this.navigation_button_text = globalThis.wantParams.widgetParam?.navigationButtonText;
    this.type = globalThis.wantParams.widgetParam?.windowMode;
    LogUtils.i(TAG, 'getParams--' + this.type.toString() + JSON.stringify(globalThis.wantParams.authParam) + JSON.stringify(globalThis.wantParams.widgetParam));
  }

  build() {
    Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.SpaceAround, alignItems: ItemAlign.Center }) {
      if (userAuth.WindowModeType.DIALOG_BOX === this.type) {
        if (this.authType.includes(2)) {
          FaceAuth({
            cancel: this.onCancel,
            confirm: this.onAccept,
            type: $type
          })
        } else if (this.authType.includes(4)) {
          FingerprintAuth({
            cancel: this.onCancel,
            confirm: this.onAccept,
            type: $type
          })
        } else {
          PasswordAuth({
            cancel: this.onCancel,
            confirm: this.onAccept,
            type: $type
          })
        }

      } else if (userAuth.WindowModeType.FULLSCREEN === this.type) {
        // full screen pin
        CustomPassword({
          cancel: this.onCancel,
          confirm: this.onCancel,
          themeType: $themeType,
          type: $type,
          authType: $authType
        })
      } else if (this.type === 6 || this.type === 9 || this.type === 10) {
        // dialog face
        FaceAuth({
          cancel: this.onCancel,
          confirm: this.onAccept,
          type: $type
        })
      } else if (this.type === 7 || this.type === 8) {
        // dialog finger

      }
    }
    .backgroundColor(Color.Pink)
    .position({ x: 0, y: this.topHeight })
    .height((this.bottomHeight-this.topHeight))
  }
}