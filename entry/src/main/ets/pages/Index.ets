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

import screen from '@ohos.screen';
import userAuth from '@ohos.userIAM.userAuth';
import { DialogType } from '../common/module/DialogType';
import FuncUtils from '../common/utils/FuncUtils';
import LogUtils from '../common/utils/LogUtils';
import Constants, { CmdType } from '../common/vm/Constants';
import CustomPassword from './components/CustomPassword';
import FaceAuth from './components/FaceAuth';
import FingerprintAuth from './components/FingerprintAuth';
import PasswordAuth from './components/PasswordAuth';

const DEFAULT_SIZE = 72;
const FIVE_SECOND = 5000;
const LAND_SCAPE = 2;
const TAG = 'Index';
const THEME_BLUR = 2;
let userAuthWidgetMgr;

@Entry
@Component
struct Index {
  @State authType: Array<userAuth.UserAuthType> = [userAuth.UserAuthType.PIN];
  @State type: string[] = [];
  @State topHeight: number = DEFAULT_SIZE;
  @State bottomHeight: number = DEFAULT_SIZE;
  @State pinSubType: string = Constants.pinNumber;
  @State dialogType: DialogType = DialogType.ALL;
  @State windowModeType: string = 'DIALOG_BOX';
  // background 1:white 2:Gaussian Blur
  @State themeType: number = THEME_BLUR;
  @State cmdData: Array<CmdType> = [];
  @Provide isLandscape: boolean = false;
  @Provide underFingerPrint: boolean = false;
  @State loadFlag: boolean = false;

  onScreenChange(): void {
    try {
      screen.getAllScreens((err, data) => {
        if (err.code) {
          LogUtils.e(TAG, 'Failed to get all screens. Cause: ' + JSON.stringify(err));
          return;
        }
        LogUtils.d(TAG, ' get all screens. result:-- ' + JSON.stringify(data));
        this.isLandscape = data[0].orientation === LAND_SCAPE;
        if (globalThis.wantParams) {
          this.getParams(globalThis.wantParams);
          this.handleAuthStart();
          this.cmdData = globalThis.wantParams?.cmd;
          LogUtils.d(TAG, 'globalThis.wantParams： ' + JSON.stringify(globalThis.wantParams));
        } else {
          LogUtils.e(TAG, 'aboutToAppear wantParams null');
        }
        if (this.isLandscape && this.underFingerPrint) {
          setTimeout(() => {
            globalThis.session?.terminateSelf();
          }, FIVE_SECOND)
        } else {
          this.loadFlag = true;
        }
      });
    } catch (exception) {
      LogUtils.e(TAG, 'getAllScreens catch exception: ' + exception);
    }
  }

  handleAuthStart(): void {
    try {
      userAuthWidgetMgr = userAuth.getUserAuthWidgetMgr(Constants.userAuthWidgetMgrVersion);
      LogUtils.i(TAG, 'getUserAuthWidgetMgr success');
      let that = this;
      userAuthWidgetMgr.on('command', {
        callback: function (result) {
          LogUtils.i(TAG, 'userAuthWidgetMgr onCommand result: ' + JSON.stringify(result));
          const cmdDataObj = JSON.parse(result?.cmdData || '{}');
          if (cmdDataObj?.cmd?.[0]?.payload?.result === Constants.userAuthWidgetMgrSuccess) {
            globalThis.session?.terminateSelf();
          } else {
            that.cmdData = cmdDataObj?.cmd || [];
            that.pinSubType = cmdDataObj?.pinSubType;
            that.handleIsUnder(cmdDataObj?.cmd || []);
          }
        }
      });
    } catch (error) {
      LogUtils.e(TAG, 'getUserAuthWidgetMgr catch error: ' + JSON.stringify(error));
    }
  }

  handleIsUnder(cmd: Array<CmdType>): void {
    cmd?.length > 0 && cmd.map((item) => {
      const { type, sensorInfo } = item.payload;
      if (type === Constants.noticeTypeFinger) {
        if (sensorInfo && JSON.stringify(sensorInfo) !== '{}') {
          const fingerPosition = JSON.parse(sensorInfo);
          if (fingerPosition.sensorType === 'UNDER_SCREEN_SENSOR' ||
          fingerPosition.sensorType === 'BOTH_SENSOR' ||
          fingerPosition.sensorType === 'SensorType1') {
            this.underFingerPrint = true;
          }
        }
      }
    });
  }

  aboutToAppear(): void {
    this.onScreenChange();
    LogUtils.d(TAG, 'aboutToAppear');
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    if (userAuthWidgetMgr) {
      userAuthWidgetMgr.off('command', {
        callback: function (result) {
          LogUtils.i(TAG, 'aboutToDisappear userAuthWidgetMgr offCommand result: ' + JSON.stringify(result));
        }
      });
    }
  }

  onPageShow(): void {
    LogUtils.i(TAG, 'onPageShow');
  }

  getParams(result): void {
    LogUtils.i(TAG, 'getParams');
    const { pinSubType, windowModeType, cmd, type, widgetContextId } = result;
    this.pinSubType = pinSubType;
    const newType = type && type.map(item => {
      switch (item) {
        case Constants.noticeTypePin:
          return userAuth.UserAuthType.PIN;
        case Constants.noticeTypeFinger:
          return userAuth.UserAuthType.FINGERPRINT;
        case Constants.noticeTypeFace:
          return userAuth.UserAuthType.FACE;
      }
    })
    globalThis.widgetContextId = widgetContextId;
    this.authType = newType;
    this.type = type;
    this.windowModeType = windowModeType;
    this.dialogType = FuncUtils.getDialogType(newType);
    this.cmdData = cmd || [];
    this.handleIsUnder(cmd || []);
  }

  build() {
    Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.SpaceAround, alignItems: ItemAlign.Center }) {
      if (this.isLandscape && this.underFingerPrint) {
        Column() {
          Text(globalThis.context.resourceManager
            .getStringSync($r('app.string.unified_authwidget_tip_verify_in_portrait_mode')))
            .height('40vp')
            .fontColor(Color.Black)
            .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
            .fontWeight(FontWeight.Medium)
        }.justifyContent(FlexAlign.End)
        .backgroundColor(Color.White)
        .width(Constants.fullContainerWidth)
        .height(Constants.fullContainerWidth)
      } else if (this.loadFlag) {
        if ('DIALOG_BOX' === this.windowModeType) {
          if (this.authType.includes(userAuth.UserAuthType.FACE)) {
            FaceAuth({
              type: $windowModeType,
              pinSubType: $pinSubType,
              dialogType: $dialogType,
              cmdData: $cmdData,
            })
          } else if (this.authType.includes(userAuth.UserAuthType.FINGERPRINT)) {
            FingerprintAuth({
              type: $windowModeType,
              pinSubType: $pinSubType,
              dialogType: $dialogType,
              cmdData: $cmdData,
            })
          } else {
            PasswordAuth({
              pinSubType: $pinSubType,
              cmdData: $cmdData
            })
          }

        } else {
          // full screen PIN
          CustomPassword({
            themeType: $themeType,
            authType: $authType,
            pinSubType: $pinSubType,
            cmdData: $cmdData,
          })
        }
      }
    }
    .onAreaChange(() => {
      FuncUtils.getWindowHeight();
    })
  }
}