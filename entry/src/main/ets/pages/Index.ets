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
import AuthUtils from '../common/utils/AuthUtils';
import FuncUtils from '../common/utils/FuncUtils';
import { GlobalObject } from '../common/utils/GlobalObject';
import LogUtils from '../common/utils/LogUtils';
import Constants, { CmdData, CmdType, CommandResultInfo, FingerPosition, WantParams,
  WidgetCommand } from '../common/vm/Constants';
import CustomPassword from './components/CustomPassword';
import FaceAuth from './components/FaceAuth';
import FingerprintAuth from './components/FingerprintAuth';
import PasswordAuth from './components/PasswordAuth';

const DEFAULT_SIZE = 72;
const FIVE_SECOND = 5000;
const LANDSCAPE = 2;
const TAG = 'Index';
let userAuthWidgetMgr: userAuth.UserAuthWidgetMgr;

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
  @State cmdData: Array<CmdType> = [];
  @State isLandscape: boolean = false;
  @Provide underFingerPrint: boolean = false;
  @State loadFlag: boolean = false;

  onScreenChange(): void {
    try {
      screen.getAllScreens((err, data) => {
        if (err.code) {
          LogUtils.error(TAG, 'Failed to get all screens. err: ' + err.code);
          GlobalObject.getObject().getSession()?.terminateSelf();
          return;
        }
        LogUtils.debug(TAG, ' get all screens. result:-- ' + JSON.stringify(data));
        this.isLandscape = data[0]?.orientation === LANDSCAPE
        || data[0]?.supportedModeInfo[0]?.width > data[0]?.supportedModeInfo[0]?.height;
        AppStorage.SetOrCreate('titleLength', (data[0]?.supportedModeInfo[0]?.width * 0.8 / fp2px(16)))
        LogUtils.debug(TAG, 'titleLength: ' + (data[0]?.supportedModeInfo[0]?.width * 0.8 / fp2px(16)));
        LogUtils.debug(TAG, 'title: ' + GlobalObject.getObject().getWantParams()?.title.length);
        AppStorage.SetOrCreate('IS_LANDSCAPE', this.isLandscape);
        LogUtils.debug(TAG, 'WantParams： ' + JSON.stringify(GlobalObject.getObject().getWantParams()));
        if (GlobalObject.getObject().getWantParams()) {
          this.getParams(GlobalObject.getObject().getWantParams());
          this.handleAuthStart();
          this.cmdData = GlobalObject.getObject().getWantParams()?.cmd as CmdType[];
        } else {
          LogUtils.error(TAG, 'aboutToAppear wantParams null');
          GlobalObject.getObject().getSession()?.terminateSelf();
        }
        if (this.isLandscape && this.underFingerPrint) {
          setTimeout(() => {
            GlobalObject.getObject().getSession()?.terminateSelf();
          }, FIVE_SECOND)
        } else {
          this.loadFlag = true;
        }
      });
    } catch (error) {
      LogUtils.error(TAG, 'getAllScreens catch error: ' + error?.code);
      GlobalObject.getObject().getSession()?.terminateSelf();
    }
  }

  handleAuthStart(): void {
    LogUtils.info(TAG, 'handleAuthStart');
    try {
      userAuthWidgetMgr = userAuth.getUserAuthWidgetMgr(Constants.userAuthWidgetMgrVersion);
      LogUtils.info(TAG, 'getUserAuthWidgetMgr success');
      let that = this;
      userAuthWidgetMgr.on('command', {
        sendCommand(result): void {
          LogUtils.info(TAG, 'userAuthWidgetMgr onCommand result: ' + JSON.stringify(result));
          const commandResultInfo: CommandResultInfo = JSON.parse(result);
          const cmdDataObj: WidgetCommand = JSON.parse(commandResultInfo?.cmdData || '{}');
          that.cmdData = cmdDataObj?.cmd || [];
          that.pinSubType = cmdDataObj?.pinSubType;
          that.handleIsUnder(cmdDataObj?.cmd || []);
        }
      });
    } catch (error) {
      LogUtils.error(TAG, 'getUserAuthWidgetMgr catch error: ' + error?.code);
      GlobalObject.getObject().getSession()?.terminateSelf?.();
    }
  }

  handleIsUnder(cmd: Array<CmdType>): void {
    try {
      LogUtils.info(TAG, 'handleIsUnder');
      cmd?.length > 0 && cmd.map((item) => {
        const payload: CmdData = item?.payload;
        if (payload.type === Constants.noticeTypeFinger) {
          if (payload.sensorInfo && JSON.stringify(payload.sensorInfo) !== '{}') {
            const fingerPosition: FingerPosition = JSON.parse(payload.sensorInfo);
            if (fingerPosition?.sensorType === 'UNDER_SCREEN_SENSOR' ||
            fingerPosition?.sensorType === 'BOTH_SENSOR' ||
            fingerPosition?.sensorType === 'SensorType1') {
              this.underFingerPrint = true;
            }
          }
        }
      });
    } catch (error) {
      LogUtils.error(TAG, 'handleIsUnder catch error: ' + error?.code);
    }
  }

  aboutToAppear(): void {
    LogUtils.debug(TAG, 'aboutToAppear');
    FuncUtils.getWindowHeight();
    this.onScreenChange();
  }

  aboutToDisappear(): void {
    LogUtils.info(TAG, 'aboutToDisappear');
    if (userAuthWidgetMgr) {
      userAuthWidgetMgr.off('command', {
        sendCommand (result): void {
          LogUtils.info(TAG, 'aboutToDisappear userAuthWidgetMgr offCommand result: ' + JSON.stringify(result));
        }
      });
    }
  }

  getParams(result: WantParams): void {
    LogUtils.info(TAG, 'getParams');
    const resultInfo: WantParams = result;
    this.pinSubType = resultInfo.pinSubType;
    const newType = resultInfo.type && resultInfo.type.map(item => {
      if (item === Constants.noticeTypePin) {
        return userAuth.UserAuthType.PIN;
      } else if (item === Constants.noticeTypeFinger) {
        return userAuth.UserAuthType.FINGERPRINT;
      } else if (item === Constants.noticeTypeFace) {
        return userAuth.UserAuthType.FACE;
      } else {
        return userAuth.UserAuthType.PIN;
      }
    })
    GlobalObject.getObject().setWidgetContextId(resultInfo.widgetContextId)
    this.authType = newType;
    this.type = resultInfo.type;
    this.windowModeType = resultInfo.windowModeType;
    this.dialogType = FuncUtils.getDialogType(newType);
    this.cmdData = resultInfo.cmd || [];
    this.handleIsUnder(resultInfo.cmd || []);
  }

  build() {
    Column() {
      if (this.isLandscape && this.underFingerPrint) {
        Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Center, alignItems: ItemAlign.End }) {
          Column() {
            Text(GlobalObject.getObject().getContext().resourceManager
              .getStringSync($r('app.string.unified_authwidget_tip_verify_in_portrait_mode').id))
              .draggable(false)
              .fontColor($r('sys.color.ohos_id_color_text_primary_contrary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Regular)
          }
          .backgroundColor($r('sys.color.ohos_id_color_instant_tip_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding({
            left: $r('app.float.padding_16'),
            top: $r('app.float.padding_8'),
            right: $r('app.float.padding_16'),
            bottom: $r('app.float.padding_8')
          })
          .margin({ bottom: $r('app.float.margin_64') })
        }
        .width(Constants.fullContainerWidth)
        .height(Constants.fullContainerHeight)
      } else if (this.loadFlag) {
        Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.SpaceAround, alignItems: ItemAlign.Center }) {
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
              authType: $authType,
              pinSubType: $pinSubType,
              cmdData: $cmdData,
            })
          }
        }
      }
    }
  }
}