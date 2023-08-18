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
import account_osAccount from '@ohos.account.osAccount';
import display from '@ohos.display';
import util from '@ohos.util';
import PassWord from '../../common/components/PassWord';
import SixPassword from '../../common/components/SixPassword';
import { DialogType } from '../../common/module/DialogType';
import AuthUtils from '../../common/utils/AuthUtils';
import FuncUtils from '../../common/utils/FuncUtils';
import LogUtils from '../../common/utils/LogUtils';
import TimeUtils from '../../common/utils/TimeUtils';
import Constants, { CmdType, FingerPosition } from '../../common/vm/Constants';

const TAG = 'FaceAuth';

let pinAuthManager;
const INTERVAL = 1000;
const THOUSANDTH = 1000;
const PADDING_24 = 24;
const MARGIN_TOP = 113;
const PIN_FACE = 1;
const PIN_FACE_FINGER = 2;
const MULTI_PIN = 4;
const SIX_PIN = 5;
const SINGLE_FACE = 6;
const SCREEN_LAND = 1;
const SCREEN_PORTRAIT = 2;
const NOTICE_DELAY = 50;
const FINGER_SENSOR_POSITION_LINE = 0.75;
const HINT_TIMES_BY_FAIL_LESS = 3;
let pinData = '';

@Component
export default struct FaceAuth {
  @State prompt: string = globalThis.context.resourceManager
    .getStringSync($r('app.string.unified_authwidget_hint_recognition'));
  @State @Watch('onTextValueChange') textValue: string = '';
  @Link @Watch('onCmdDataChange') cmdData: Array<CmdType>;
  @StorageLink('IS_LANDSCAPE') IS_LANDSCAPE: boolean = false;
  @State isEdit: boolean = true;
  // 0:six number 1:arbitrary character 2:arbitrary number
  @Link type: string;
  @Link pinSubType: string;
  @Link dialogType: DialogType;
  @State inputValue: string = '';
  @State dialogTypeFlag: number = this.dialogType === DialogType.PIN_FACE ?
    PIN_FACE : (this.dialogType === DialogType.ALL ? PIN_FACE_FINGER : SINGLE_FACE);
  // 1:Portrait screen 2:Landscape mode
  @State screenType: number = 0;
  @State fingerPositionY: number = 0;
  @State fingerPosition: FingerPosition = {
    sensorType: ''
  }
  @State screen: number[] = [];
  @State faceLock: boolean = false;
  @State fingerLock: boolean = false;
  @State isPinFaceFinger: boolean = false;
  @StorageLink('SYSTEM_NAVIGATION_BAR_HEIGHT') SYSTEM_NAVIGATION_BAR_HEIGHT: number = 0;

  countTime(freezingTime): void {
    const TRY_AGAIN = globalThis.context.resourceManager.getStringSync($r('app.string.unified_authwidget_postretry'));
    let promptText: string = '';
    let freezingMillisecond = freezingTime;
    if (freezingMillisecond > 0) {
      promptText = TimeUtils.getFreezingTimeNm(freezingMillisecond, globalThis.context);
      promptText = globalThis.context.resourceManager
        .getStringSync($r('app.string.unified_authwidget_many_failures')) + promptText + TRY_AGAIN;
      setTimeout(this.countTime.bind(this), INTERVAL, freezingTime - INTERVAL);
    } else {
      promptText = ' ';
      this.isEdit = true;
    }
    this.inputValue = promptText;
  }

  aboutToAppear(): void {
    LogUtils.debug(TAG, 'aboutToAppear');
    try {
      if (this.cmdData && this.cmdData.length > 0) {
        this.onCmdDataChange('first');
      }

      if (this.isPinFaceFinger) {
        let tempPosition = this.fingerPosition.udSensorCenterYInThousandth / this.screen[1];
        FuncUtils.judgmentOverflow(tempPosition);
        let tempFingerPositionY = px2vp(this.screen[1]) * this.fingerPosition.udSensorCenterYInThousandth;
        FuncUtils.judgmentOverflow(tempFingerPositionY);
        if (tempPosition < FINGER_SENSOR_POSITION_LINE) {
          this.fingerPositionY = (tempFingerPositionY / THOUSANDTH) - px2vp(this.screen[1])
          + this.SYSTEM_NAVIGATION_BAR_HEIGHT - MARGIN_TOP - px2vp(this.fingerPosition.udSensorRadiusInPx);
        } else {
          this.fingerPositionY = (tempFingerPositionY / THOUSANDTH) - px2vp(this.screen[1])
          + this.SYSTEM_NAVIGATION_BAR_HEIGHT - PADDING_24 - px2vp(this.fingerPosition.udSensorRadiusInPx);
        }
        FuncUtils.judgmentOverflow(this.fingerPositionY);
      }
      LogUtils.info(TAG, 'aboutToAppear this.fingerPositionY: ' + this.fingerPositionY);
      if (this.dialogType === DialogType.PIN_FACE || this.dialogType === DialogType.FACE) {
        this.prompt = globalThis.context.resourceManager
          .getStringSync($r('app.string.unified_authwidget_hint_recognition'));
        AuthUtils.getInstance().sendNotice('EVENT_AUTH_TYPE_READY', [Constants.noticeTypeFace]);
      } else if (this.dialogType === DialogType.ALL) {
        AuthUtils.getInstance()
          .sendNotice('EVENT_AUTH_TYPE_READY', [Constants.noticeTypeFinger, Constants.noticeTypeFace]);
      } else {
        LogUtils.error(TAG, 'aboutToAppear not support type');
        globalThis.session?.terminateSelf?.();
      }
      pinAuthManager = new account_osAccount.PINAuth();
      pinAuthManager.registerInputer({
        onGetData: (authSubType, callback) => {
          LogUtils.info(TAG, 'aboutToAppear registerInputer onGetData');
          let uint8PW = FuncUtils.getUint8PW(pinData);
          callback.onSetData(authSubType, uint8PW);
        }
      });
    } catch (error) {
      LogUtils.error(TAG, 'aboutToAppear catch error: ' + error?.code);
      globalThis.session?.terminateSelf?.();
    }
  }

  aboutToDisappear(): void {
    pinAuthManager?.unregisterInputer?.();
  }

  toPin(): void {
    if ([DialogType.PIN_FACE, DialogType.ALL].includes(this.dialogType)) {
      LogUtils.debug(TAG, 'toPin this.dialogType: ' + this.dialogType);
      if (this.dialogType === DialogType.ALL) {
        AuthUtils.getInstance().sendNotice(Constants.noticeEventCancel, [Constants.noticeTypeFace, Constants.noticeTypeFinger]);
      } else if (this.dialogType === DialogType.PIN_FACE) {
        AuthUtils.getInstance().sendNotice(Constants.noticeEventCancel, [Constants.noticeTypeFace]);
      } else {
        AuthUtils.getInstance().sendNotice(Constants.noticeEventCancel, [Constants.noticeTypeFinger]);
      }
      if (this.pinSubType !== Constants.pinSix) {
        this.dialogTypeFlag = MULTI_PIN;
      } else {
        this.dialogTypeFlag = SIX_PIN;
      }
    }
  }

  sendFaceEvent(): void {
    if (!this.faceLock) {
      this.prompt = globalThis.context.resourceManager
        .getStringSync($r('app.string.unified_authwidget_hint_recognition'));
      AuthUtils.getInstance().sendNotice('EVENT_AUTH_TYPE_READY', [Constants.noticeTypeFace]);
    }
  }

  sendFingerEvent(): void {
    if (!this.fingerLock) {
      AuthUtils.getInstance().sendNotice('EVENT_AUTH_TYPE_READY', [Constants.noticeTypeFinger]);
    }
  }

  onTextValueChange(): void {
    pinData = this.textValue;
  }

  onFontColor(prompt: string, context: Context): Resource {
    switch (prompt) {
      case context?.resourceManager
      ?.getStringSync($r('app.string.unified_authwidget_hint_face_verify_fail_click_retry_s1')):
      case context?.resourceManager
      ?.getStringSync($r('app.string.unified_authwidget_title_number_failed_face_forbidden')):
      case context?.resourceManager
      ?.getStringSync($r('app.string.unified_authwidget_title_number_failed_fp_forbidden')):
        return $r('sys.color.ohos_id_color_warning');
      case context?.resourceManager
      ?.getStringSync($r('app.string.unified_authwidget_hint_recognition')):
      case context?.resourceManager
      ?.getStringSync($r('app.string.unified_authwidget_hint_recognize_success')):
      case context?.resourceManager
      ?.getStringSync($r('app.string.unified_authwidget_hint_inscreen_fp')):
        return $r('sys.color.ohos_id_color_text_secondary');
    }
  }

  onCmdDataChange(num?: string): void {
    this.cmdData.length > 0 && this.cmdData.map(async (item) => {
      const { type, remainAttempts, lockoutDuration,sensorInfo} = item.payload;
      switch (type) {
        case Constants.noticeTypePin:
          if (remainAttempts) {
            this.inputValue = globalThis.context.resourceManager
              .getStringSync($r('app.string.unified_authwidget_hint_pwd_error'));
            this.textValue = '';
            if (num === 'first') {
              this.inputValue = '';
            }
            if (remainAttempts < HINT_TIMES_BY_FAIL_LESS) {
              this.inputValue = globalThis.context.resourceManager
                .getStringSync($r('app.string.unified_authwidget_pwd_error_can_try'))
              + remainAttempts + globalThis.context.resourceManager
                .getStringSync($r('app.string.unified_authwidget_frequency'));
            }
          }
          if (remainAttempts === 0 && lockoutDuration) {
            this.countTime(lockoutDuration);
            this.textValue = '';
            this.toPin();
            this.isEdit = false;
          }
          break;
        case Constants.noticeTypeFace:
          if ([SIX_PIN, MULTI_PIN].includes(this.dialogTypeFlag)) {
            return;
          }
          if (remainAttempts) {
            this.prompt = globalThis.context.resourceManager
              .getStringSync($r('app.string.unified_authwidget_hint_face_verify_fail_click_retry_s1'));
            this.faceLock = false;
          }
          if (num === 'first') {
            this.prompt = globalThis.context.resourceManager
              .getStringSync($r('app.string.unified_authwidget_hint_recognition'));
          }
          if (remainAttempts === 0) {
            this.prompt = globalThis.context.resourceManager
              .getStringSync($r('app.string.unified_authwidget_title_number_failed_face_forbidden'));
            this.faceLock = true;
            if (this.dialogType === DialogType.ALL) {
              if (this.fingerLock) {
                this.toPin();
              }
            } else {
              this.toPin();
            }
          }
          break;
        case Constants.noticeTypeFinger:
          if ([SIX_PIN, MULTI_PIN].includes(this.dialogTypeFlag)) {
            return;
          }
          if (sensorInfo && JSON.stringify(sensorInfo) !== '{}') {
            this.fingerPosition = JSON.parse(sensorInfo);
            const displayClass = display.getDefaultDisplaySync();
            this.screen = [displayClass.width, displayClass.height];
            switch (JSON.parse(sensorInfo)?.sensorType) {
              case 'NON_SENSOR':
              case 'OUT_OF_SCREEN_SENSOR': {
                this.dialogTypeFlag = PIN_FACE;
                break;
              }
              default:
                this.isPinFaceFinger = true;
                let tempPositionLine = JSON.parse(sensorInfo).udSensorCenterYInThousandth / displayClass.height;
                FuncUtils.judgmentOverflow(tempPositionLine);
                if (tempPositionLine < FINGER_SENSOR_POSITION_LINE) {
                  if (!this.IS_LANDSCAPE && ![SIX_PIN, MULTI_PIN].includes(this.dialogTypeFlag)) {
                    this.screenType = SCREEN_LAND;
                  }
                } else if (tempPositionLine > FINGER_SENSOR_POSITION_LINE) {
                  if (!this.IS_LANDSCAPE && ![SIX_PIN, MULTI_PIN].includes(this.dialogTypeFlag)) {
                    this.screenType = SCREEN_PORTRAIT;
                  }
                }
                break;
            }
          }
          if (remainAttempts) {
            this.prompt = globalThis.context.resourceManager
              .getStringSync($r('app.string.unified_authwidget_hint_fp_retry_s2'));
            this.fingerLock = false;
            if (num !== 'first' && remainAttempts > 0) {
              setTimeout(() => {
                AuthUtils.getInstance().sendNotice('EVENT_AUTH_TYPE_READY', [Constants.noticeTypeFinger]);
              }, NOTICE_DELAY);
            }
          }
          if (num === 'first') {
            this.prompt = globalThis.context.resourceManager
              .getStringSync($r('app.string.unified_authwidget_hint_normal_fp_only'));
          }
          if (remainAttempts === 0) {
            this.prompt = globalThis.context.resourceManager
              .getStringSync($r('app.string.unified_authwidget_title_number_failed_fp_forbidden'));
            this.fingerLock = true;
            if (this.dialogType === DialogType.ALL) {
              if (this.faceLock) {
                this.toPin();
              }
            } else {
              this.toPin();
            }
          }
          break;
        default:
          LogUtils.error(TAG, 'onCmdDataChange default');
          globalThis.session?.terminateSelf?.();
          break;
      }
    })
  }

  handleCancel(): void {
    if (this.dialogTypeFlag === SIX_PIN || this.dialogTypeFlag === MULTI_PIN) {
      AuthUtils.getInstance().sendNotice(Constants.noticeEventCancel, [Constants.noticeTypePin]);
    } else {
      AuthUtils.getInstance().sendNotice(Constants.noticeEventCancel, globalThis?.wantParams?.type || []);
    }
    globalThis.session?.terminateSelf?.();
  }

  build() {
    Column() {
      GridRow({
        columns: { xs: 4, sm: 4, md: 8, lg: 12 },
        gutter: { x: 24, y: 24 },
        breakpoints: { value: Constants.deviceDpi,
          reference: BreakpointsReference.WindowSize },
        direction: GridRowDirection.Row
      }) {
        GridCol({
          span: { xs: 4, sm: 4, md: 4, lg: 6 },
          offset: { md: 2, lg: 3 },
        }) {
          if (this.isPinFaceFinger) {
            if (this.dialogTypeFlag === MULTI_PIN) {
              Column() {
                // Password 32-bit
                Column() {
                  PassWord({
                    textValue: $textValue,
                    inputValue: $inputValue,
                    isEdit: $isEdit,
                    pinSubType: $pinSubType
                  })
                  Row() {
                    Column() {
                      Button($r('app.string.unified_authwidget_cancel'), { stateEffect: true })
                        .id('cancelBtnMixedPinFaceAuth')
                        .margin({ left: $r('app.float.content_padding') })
                        .width(Constants.ninetyPercentWidth)
                        .height($r('app.float.btn_height'))
                        .fontSize($r('sys.float.ohos_id_text_size_button1'))
                        .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                        .fontWeight(FontWeight.Medium)
                        .backgroundColor(Color.Transparent)
                        .onClick(() => {
                          this.textValue = '';
                          this.handleCancel();
                        })
                    }.width(Constants.halfContainerWidth)

                    Divider()
                      .vertical(true)
                      .height($r('app.float.digital_password_mask_height'))
                      .color($r('sys.color.ohos_id_color_list_separator'))
                      .width($r('app.float.divider_width'))
                    Column() {
                      Button($r('app.string.unified_authwidget_confirm'))
                        .id('okBtnFaceAuth')
                        .margin({ right: $r('app.float.content_padding') })
                        .width(Constants.ninetyPercentWidth)
                        .height($r('app.float.btn_height'))
                        .fontSize($r('sys.float.ohos_id_text_size_button1'))
                        .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                        .fontWeight(FontWeight.Medium)
                        .backgroundColor(Color.Transparent)
                        .onClick(async (e) => {
                          AuthUtils.getInstance().sendNotice('EVENT_AUTH_TYPE_READY', [Constants.noticeTypePin]);
                        })
                    }.width(Constants.halfContainerWidth)
                  }
                  .height($r('app.float.btn_height'))
                  .margin({ top: $r('app.float.element_margin'), bottom: $r('app.float.content_padding') })
                }
              }
              .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
              .borderRadius($r('sys.float.ohos_id_corner_radius_dialog'))
              .margin({
                left: ($r('sys.float.ohos_id_dialog_margin_start')),
                right: ($r('sys.float.ohos_id_dialog_margin_end')),
                bottom: this.IS_LANDSCAPE ? '0' : ($r('sys.float.ohos_id_dialog_margin_bottom'))
              })
            } else if (this.dialogTypeFlag === SIX_PIN) {
              Column() {
                // Password 6-bit
                Column() {
                  SixPassword({
                    textValue: $textValue,
                    inputValue: $inputValue,
                    isEdit: $isEdit
                  })
                  Button($r('app.string.unified_authwidget_cancel'), { stateEffect: true })
                    .id('cancelBtnSixPinFaceAuth')
                    .onClick(() => {
                      this.handleCancel();
                      this.textValue = '';
                    })
                    .backgroundColor(Color.Transparent)
                    .height($r('app.float.btn_height'))
                    .width(Constants.halfContainerWidth)
                    .margin({ top: $r('app.float.element_margin'), bottom: $r('app.float.content_padding') })
                    .fontSize($r('sys.float.ohos_id_text_size_button1'))
                    .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                    .fontWeight(FontWeight.Medium)
                }
              }
              .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
              .borderRadius($r('sys.float.ohos_id_corner_radius_dialog'))
              .margin({
                left: ($r('sys.float.ohos_id_dialog_margin_start')),
                right: ($r('sys.float.ohos_id_dialog_margin_end')),
                bottom: this.IS_LANDSCAPE ? '0' : ($r('sys.float.ohos_id_dialog_margin_bottom'))
              })
            } else if (this.dialogTypeFlag === PIN_FACE_FINGER && this.screenType === SCREEN_PORTRAIT) {
              Column() {
                // The first form of facial fingerprint password
                Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                  Image($r('app.media.ic_public_cancel'))
                    .draggable(false)
                    .id('cancelImgAllFaceAuth')
                    .width($r('app.float.digital_password_mask_height'))
                    .height($r('app.float.digital_password_mask_height'))
                    .margin({
                      top: $r('app.float.digital_password_mask_height'),
                      left: $r('app.float.digital_password_mask_height')
                    })
                    .onClick(() => {
                      this.textValue = '';
                      this.handleCancel();
                    })
                  Button($r('app.string.unified_authwidget_usepwd'))
                    .id('usePwdBtnAllFaceAuth')
                    .backgroundColor(Color.White)
                    .height($r('app.float.digital_password_mask_height'))
                    .padding(0)
                    .margin({
                      top: $r('app.float.digital_password_mask_height'),
                      right: $r('app.float.digital_password_mask_height')
                    })
                    .fontColor($r('sys.color.ohos_id_color_activated'))
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight(FontWeight.Medium)
                    .onClick(() => {
                      this.inputValue = ' ';
                      this.toPin();
                    })
                }

                Image($r('app.media.error_faceID'))
                  .draggable(false)
                  .id('imgAllFaceAuth')
                  .width($r('app.float.image_small'))
                  .height($r('app.float.image_small'))
                  .margin({ top: $r('app.float.content_padding'), bottom: $r('app.float.content_padding') })
                  .colorBlend($r('sys.color.ohos_id_color_activated'))
                  .onClick(() => {
                    this.sendFaceEvent();
                  })
                Text(globalThis.wantParams.title)
                  .draggable(false)
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
                Text(this.prompt)
                  .draggable(false)
                  .id('resetPromptTextAllFaceAuth')
                  .margin({ top: $r('app.float.element_margin') })
                  .height($r('app.float.size_24'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor(this.onFontColor(this.prompt, globalThis.context))
                Image($r('app.media.ic_blue_fingerprint'))
                  .draggable(false)
                  .id('blueFingerprintImgAllFaceAuth')
                    // radius
                  .width(px2vp(this.fingerPosition.udSensorRadiusInPx * 2))
                  .height(px2vp(this.fingerPosition.udSensorRadiusInPx * 2))
                  .margin({
                    top: $r('app.float.digital_password_mask_height'),
                    bottom: $r('app.float.digital_password_mask_height')
                  })
                  .onClick(() => {
                    this.sendFingerEvent();
                  })
              }
              .position({ y: this.fingerPositionY })
              .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
              .borderRadius($r('sys.float.ohos_id_corner_radius_dialog'))
              .margin({
                left: ($r('sys.float.ohos_id_dialog_margin_start')),
                right: ($r('sys.float.ohos_id_dialog_margin_end')),
                bottom: ($r('sys.float.ohos_id_dialog_margin_bottom'))
              })
            } else if (this.dialogTypeFlag === PIN_FACE_FINGER && this.screenType === SCREEN_LAND) {
              Column() {
                // Facial fingerprint password, second form
                Image($r('app.media.error_faceID'))
                  .draggable(false)
                  .id('errFaceImgFaceAuth')
                  .width($r('app.float.image_small'))
                  .height($r('app.float.image_small'))
                  .margin({ top: $r('app.float.content_padding_top'), bottom: $r('app.float.content_padding') })
                  .colorBlend($r('sys.color.ohos_id_color_activated'))
                  .onClick(() => {
                    this.sendFaceEvent();
                  })
                Text(globalThis.wantParams.title).fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .draggable(false)
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))

                Image($r('app.media.ic_blue_fingerprint'))
                  .draggable(false)
                  .id('blueFingerprintImgFaceAuth')
                    // radius
                  .width(px2vp(this.fingerPosition.udSensorRadiusInPx * 2))
                  .height(px2vp(this.fingerPosition.udSensorRadiusInPx * 2))
                  .margin({ top: $r('app.float.content_padding') })
                Text(this.prompt)
                  .draggable(false)
                  .margin({ top: $r('app.float.content_padding') })
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .height($r('app.float.size_24'))
                  .fontColor(this.onFontColor(this.prompt, globalThis.context))
                  .onClick(() => {
                    if (this.prompt === globalThis?.context?.resourceManager
                    ?.getStringSync($r('app.string.unified_authwidget_hint_face_verify_fail_click_retry_s1'))) {
                      this.sendFaceEvent();
                    }
                  })
                Row() {
                  Column() {
                    Button($r('app.string.unified_authwidget_cancel'), { stateEffect: true })
                      .id('cancelBtnFaceAuth')
                      .margin({ left: $r('app.float.content_padding') })
                      .width(Constants.ninetyPercentWidth)
                      .height($r('app.float.btn_height'))
                      .fontSize($r('sys.float.ohos_id_text_size_button1'))
                      .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor(Color.Transparent)
                      .onClick(() => {
                        this.handleCancel();
                        this.textValue = '';
                      })
                  }.width(Constants.halfContainerWidth)

                  Divider()
                    .vertical(true)
                    .height($r('app.float.digital_password_mask_height'))
                    .color($r('sys.color.ohos_id_color_list_separator'))
                    .width($r('app.float.divider_width'))
                  Column() {
                    Button($r('app.string.unified_authwidget_usepwd'))
                      .id('usePwdBtnFaceAuth')
                      .margin({ right: $r('app.float.content_padding') })
                      .width(Constants.ninetyPercentWidth)
                      .height($r('app.float.btn_height'))
                      .fontSize($r('sys.float.ohos_id_text_size_button1'))
                      .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor(Color.Transparent)
                      .onClick(() => {
                        this.toPin();
                      })

                  }.width(Constants.halfContainerWidth)

                }
                .height($r('app.float.btn_height'))
                .margin({ top: $r('app.float.element_margin'), bottom: $r('app.float.content_padding') })
              }
              .position({ y: this.fingerPositionY })
              .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
              .borderRadius($r('sys.float.ohos_id_corner_radius_dialog'))
              .margin({
                left: ($r('sys.float.ohos_id_dialog_margin_start')),
                right: ($r('sys.float.ohos_id_dialog_margin_end')),
                bottom: ($r('sys.float.ohos_id_dialog_margin_bottom'))
              })
            }

          } else {
            Column() {
              if (this.dialogTypeFlag === PIN_FACE) {
                // Pin FACE
                Text(globalThis.wantParams.title)
                  .draggable(false)
                  .id('titlePinFace')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .margin({ top: $r('app.float.content_padding_top') })
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  .fontWeight(FontWeight.Medium)
                Image(this.prompt !== globalThis.context.resourceManager
                  .getStringSync($r('app.string.unified_authwidget_hint_recognize_success'))
                  ? $r('app.media.error_faceID') : $r('app.media.right_faceID'))
                  .draggable(false)
                  .margin({
                    top: $r('app.float.digital_password_mask_height'),
                    bottom: $r('app.float.digital_password_mask_height')
                  })
                  .width($r('app.float.image_size'))
                  .height($r('app.float.image_size'))
                  .colorBlend($r('sys.color.ohos_id_color_activated'))
                  .onClick(() => {
                    this.sendFaceEvent();
                  })
                Text(this.prompt).fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .draggable(false)
                  .fontColor(this.onFontColor(this.prompt, globalThis.context))
                  .height($r('app.float.size_24'))
                  .onClick(() => {
                    this.sendFaceEvent();
                  })
                Row() {
                  Column() {
                    Button($r('app.string.unified_authwidget_cancel'), { stateEffect: true })
                      .id('cancelBtnPinFaceAuth')
                      .margin({ left: $r('app.float.content_padding') })
                      .width(Constants.ninetyPercentWidth)
                      .height($r('app.float.btn_height'))
                      .fontSize($r('sys.float.ohos_id_text_size_button1'))
                      .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor(Color.Transparent)
                      .onClick(() => {
                        this.handleCancel();
                      })
                  }.width(Constants.halfContainerWidth)

                  Divider()
                    .vertical(true)
                    .height($r('app.float.digital_password_mask_height'))
                    .color($r('sys.color.ohos_id_color_list_separator'))
                    .width($r('app.float.divider_width'))
                  Column() {
                    Button($r('app.string.unified_authwidget_usepwd'))
                      .id('usePwdPinFaceAuth')
                      .margin({ right: $r('app.float.content_padding') })
                      .width(Constants.ninetyPercentWidth)
                      .height($r('app.float.btn_height'))
                      .fontSize($r('sys.float.ohos_id_text_size_button1'))
                      .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor(Color.Transparent)
                      .onClick(() => {
                        this.inputValue = ' ';
                        this.toPin();
                      })
                  }.width(Constants.halfContainerWidth)

                }
                .height($r('app.float.btn_height'))
                .margin({ top: $r('app.float.element_margin'), bottom: $r('app.float.content_padding') })
              }
              if (this.dialogTypeFlag === MULTI_PIN) {
                // Password 32-bit
                Column() {
                  PassWord({
                    textValue: $textValue,
                    inputValue: $inputValue,
                    isEdit: $isEdit,
                    pinSubType: $pinSubType
                  })
                  Row() {
                    Column() {
                      Button($r('app.string.unified_authwidget_cancel'), { stateEffect: true })
                        .id('cancelBtnMixedPinFaceAuth')
                        .margin({ left: $r('app.float.content_padding') })
                        .width(Constants.ninetyPercentWidth)
                        .height($r('app.float.btn_height'))
                        .fontSize($r('sys.float.ohos_id_text_size_button1'))
                        .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                        .fontWeight(FontWeight.Medium)
                        .backgroundColor(Color.Transparent)
                        .onClick(() => {
                          this.textValue = '';
                          this.handleCancel();
                        })
                    }.width(Constants.halfContainerWidth)

                    Divider()
                      .vertical(true)
                      .height($r('app.float.digital_password_mask_height'))
                      .color($r('sys.color.ohos_id_color_list_separator'))
                      .width($r('app.float.divider_width'))
                    Column() {
                      Button($r('app.string.unified_authwidget_confirm'))
                        .id('okBtnFaceAuth')
                        .margin({ right: $r('app.float.content_padding') })
                        .width(Constants.ninetyPercentWidth)
                        .height($r('app.float.btn_height'))
                        .fontSize($r('sys.float.ohos_id_text_size_button1'))
                        .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                        .fontWeight(FontWeight.Medium)
                        .backgroundColor(Color.Transparent)
                        .onClick(async (e) => {
                          AuthUtils.getInstance().sendNotice('EVENT_AUTH_TYPE_READY', [Constants.noticeTypePin]);
                        })
                    }.width(Constants.halfContainerWidth)
                  }
                  .height($r('app.float.btn_height'))
                  .margin({ top: $r('app.float.element_margin'), bottom: $r('app.float.content_padding') })
                }

              }
              if (this.dialogTypeFlag === SIX_PIN) {
                // Password 6-bit
                Column() {
                  SixPassword({
                    textValue: $textValue,
                    inputValue: $inputValue,
                    isEdit: $isEdit
                  })
                  Button($r('app.string.unified_authwidget_cancel'), { stateEffect: true })
                    .id('cancelBtnSixPinFaceAuth')
                    .onClick(() => {
                      this.handleCancel();
                      this.textValue = '';
                    })
                    .backgroundColor(Color.Transparent)
                    .height($r('app.float.btn_height'))
                    .width(Constants.halfContainerWidth)
                    .margin({ top: $r('app.float.element_margin'), bottom: $r('app.float.content_padding') })
                    .fontSize($r('sys.float.ohos_id_text_size_button1'))
                    .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                    .fontWeight(FontWeight.Medium)
                }
              }
              if (this.dialogTypeFlag === SINGLE_FACE) {
                // Single FACE
                Text(globalThis.wantParams.title)
                  .draggable(false)
                  .id('titleFaceAuth')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .margin({ top: $r('app.float.content_padding_top') })
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  .fontWeight(FontWeight.Medium)
                Image(this.prompt !== globalThis.context.resourceManager
                  .getStringSync($r('app.string.unified_authwidget_hint_recognize_success'))
                  ? $r('app.media.error_faceID') : $r('app.media.right_faceID'))
                  .id('imageFaceAuth')
                  .draggable(false)
                  .margin({
                    top: $r('app.float.digital_password_mask_height'),
                    bottom: $r('app.float.digital_password_mask_height')
                  })
                  .width($r('app.float.image_size'))
                  .height($r('app.float.image_size'))
                  .colorBlend($r('sys.color.ohos_id_color_activated'))
                  .onClick(() => {
                    this.sendFaceEvent();
                  })
                Text(this.prompt)
                  .draggable(false)
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .id('textFaceAuth')
                  .height($r('app.float.size_24'))
                  .fontColor(this.onFontColor(this.prompt, globalThis.context))
                  .onClick(() => {
                    this.sendFaceEvent();
                  })
                if (!globalThis.wantParams?.navigationButtonText) {
                  Row() {
                    Column() {
                      Button($r('app.string.unified_authwidget_cancel'), { stateEffect: true })
                        .id('cancelBtnAllFace')
                        .onClick(() => {
                          this.handleCancel();
                        })
                        .backgroundColor(Color.Transparent)
                        .height($r('app.float.btn_height'))
                        .width(Constants.halfContainerWidth)
                        .fontSize($r('sys.float.ohos_id_text_size_button1'))
                        .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                        .fontWeight(FontWeight.Medium)
                    }.width(Constants.fullContainerHeight)
                  }
                  .height($r('app.float.btn_height'))
                  .padding({ left: $r('app.float.content_padding'), right: $r('app.float.content_padding') })
                  .margin({ top: $r('app.float.element_margin'), bottom: $r('app.float.content_padding') })
                } else {
                  Row() {
                    Column() {
                      Button($r('app.string.unified_authwidget_cancel'), { stateEffect: true })
                        .margin({ left: $r('app.float.content_padding') })
                        .width(Constants.ninetyPercentWidth)
                        .height($r('app.float.btn_height'))
                        .fontSize($r('sys.float.ohos_id_text_size_button1'))
                        .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                        .fontWeight(FontWeight.Medium)
                        .backgroundColor(Color.Transparent)
                        .onClick(() => {
                          this.handleCancel();
                        })
                    }.width(Constants.halfContainerWidth)

                    Divider()
                      .vertical(true)
                      .height($r('app.float.digital_password_mask_height'))
                      .color($r('sys.color.ohos_id_color_list_separator'))
                      .width($r('app.float.divider_width'))
                    Column() {
                      Button(globalThis.wantParams?.navigationButtonText)
                        .onClick(() => {
                          AuthUtils.getInstance().sendNotice('EVENT_AUTH_USER_NAVIGATION', [Constants.noticeTypeFace]);
                          globalThis.session?.terminateSelf?.();
                        })
                        .margin({ right: $r('app.float.content_padding') })
                        .width(Constants.ninetyPercentWidth)
                        .height($r('app.float.btn_height'))
                        .fontSize($r('sys.float.ohos_id_text_size_button1'))
                        .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                        .fontWeight(FontWeight.Medium)
                        .backgroundColor(Color.Transparent)
                    }.width(Constants.halfContainerWidth)
                  }
                  .height($r('app.float.btn_height'))
                  .margin({ top: $r('app.float.element_margin'), bottom: $r('app.float.content_padding') })
                }
              }
            }
            .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_dialog'))
            .margin({
              left: ($r('sys.float.ohos_id_dialog_margin_start')),
              right: ($r('sys.float.ohos_id_dialog_margin_end')),
              bottom: this.IS_LANDSCAPE ? '0' : ($r('sys.float.ohos_id_dialog_margin_bottom'))
            })
          }
        }
      }
    }
    .margin(this.IS_LANDSCAPE ? '0' : { bottom: this.SYSTEM_NAVIGATION_BAR_HEIGHT })
    .height(Constants.fullContainerHeight)
    .justifyContent(this.IS_LANDSCAPE ? FlexAlign.Center : FlexAlign.End)
    .backgroundColor(Color.Transparent)
    .id('faceAuth')
  }
}
