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
import userAuth from '@ohos.userIAM.userAuth';
import util from '@ohos.util';
import Pwd from '../../common/components/Pwd'
import SixPwd from '../../common/components/SixPwd'
import LogUtils from '../../common/utils/LogUtils';
import TimeUtils from '../../common/utils/TimeUtils';
import Constants from '../../common/vm/Constants';

let pinAuthManager;
const TAG = "FaceAuth";

let pinData = '';

@Component
export default struct FaceAuth {
  @State prompt: string = Constants.FACE_DOING
  @State @Watch('onFlagChange') controllerFlag: boolean = false
  @State @Watch('onTextValueChange') textValue: string = "";
  @State isEdit: boolean = true
  // 0:six number 1:arbitrary character 2:arbitrary number
  @Link type: string
  @State inputValue: string = ""
  @State flag: boolean = true
  @State flagN: number = this.type === '6' ? 1 : (this.type === '10' ? 2 : 6);
  controller: CustomDialogController
  cancel: () => void
  confirm: () => void

  checkPassword(type: String) {
    // check callback
    let userAuthWidgetMgr;

    try {
      let that = this;
      userAuthWidgetMgr = userAuth.getUserAuthWidgetMgr(1);
      LogUtils.d(TAG, 'getUserAuthWidgetMgr success');
      userAuthWidgetMgr.on('command', {
        callback: function (result) {

          LogUtils.d(TAG, 'getUserAuthWidgetMgr onCommand result: ' + JSON.stringify(result));
          const cmdData = JSON.parse(result?.cmdData);
          const authType = cmdData?.cmd?.[0]?.payload?.type;
          switch (authType) {
            case 'face':
              if (cmdData?.cmd?.[0]?.payload?.result !== 0) {
                // frequency
                const frequency = cmdData?.cmd?.[0]?.payload?.remainAttempts;
                if (frequency) {
                  that.prompt = Constants.RESET_AGAIN;
                }
                // countdown
                if (frequency === 0) {
                  that.prompt = Constants.FACE_LOCK;
                }
              } else {
                that.controllerFlag = true;
              }
              break;
            case 'fingerprint':
              if (cmdData?.cmd?.[0]?.payload?.result !== 0) {
                // frequency
                const frequency = cmdData?.cmd?.[0]?.payload?.remainAttempts;
                if (frequency) {
                  that.prompt = Constants.AGAIN_FINGER;
                }
                if (frequency === 0) {
                  that.prompt = Constants.FINGER_LOCK;
                }
                // countdown
              } else {
                // check success
                that.controllerFlag = true;
              }
            default:
              break;
          }

        }
      });
      LogUtils.d(TAG, 'getUserAuthWidgetMgr success: ' + JSON.stringify(userAuthWidgetMgr));
    } catch (error) {
      LogUtils.e(TAG, 'getUserAuthWidgetMgr catch error: ' + JSON.stringify(error));
    }
    // check
    try {
      const eventData = {
        // widgetContextId from onCreate
        widgetContextId: 123456,
        event: 'EVENT_AUTH_TYPE_READY',
        version: '1',
        payload: {
          type: [type]
        }
      };
      const jsonEventData = JSON.stringify(eventData);
      LogUtils.d(TAG, 'sendNotice start eventData: ' + jsonEventData);
      userAuth.sendNotice(1, jsonEventData);
      LogUtils.d(TAG, 'sendNotice success');
    } catch (error) {
      LogUtils.e(TAG, 'sendNotice catch error: ' + JSON.stringify(error));
    }
  }

  countTime(freezingTime) {
    const TRY_AGAIN = "后重试"
    let promptText: string = '';
    let freezingMillisecond = freezingTime;
    if (freezingMillisecond > 0) {
      promptText = TimeUtils.getFreezingTimeNm(freezingMillisecond);
      promptText += TRY_AGAIN;
      setTimeout(this.countTime.bind(this), 1000, freezingTime - 1000)
    } else {
      promptText = Constants.INPUT_PASSWORD
      this.isEdit = true
    }
    this.inputValue = promptText;
  }

  aboutToAppear() {
    this.checkPassword(Constants.NOTICE_TYPE_FACE)
    try {
      LogUtils.d(TAG, 'PINAuth start');
      pinAuthManager = new account_osAccount.PINAuth();
      LogUtils.d(TAG, 'PINAuth new success: ' + pinData);
      pinAuthManager.registerInputer({
        onGetData: (authSubType, callback) => {
          let textEncoder = new util.TextEncoder();
          let uint8PW = textEncoder.encode(pinData);
          callback.onSetData(authSubType, uint8PW);
        }
      });
    } catch (error) {
      LogUtils.e(TAG, 'PINAuth catch error: ' + JSON.stringify(error));
    }
  }

  aboutToDisappear() {
    pinAuthManager?.unregisterInputer?.()
  }

  onTextValueChange() {
    pinData = this.textValue
  }

  onFlagChange() {
    if (this.controllerFlag) {
      globalThis.session?.terminateSelf();
    }
  }

  onCancel() {
    LogUtils.i(TAG, 'onCancel Callback when the first button is clicked')
  }

  onAccept() {
    LogUtils.i(TAG, 'onAccept Callback when the second button is clicked')
  }

  existApp() {
    LogUtils.i(TAG, 'existApp Click the callback in the blank area')
  }

  build() {
    Column() {
      GridRow({
        columns: 8,
        gutter: { x: 5, y: 10 },
        breakpoints: { value: ['360vp', '780vp'],
          reference: BreakpointsReference.WindowSize },
        direction: GridRowDirection.Row
      }) {
        GridCol({ span: { xs: 0, sm: 0, md: 2, lg: 2 } })
          .visibility(Visibility.Hidden)
        GridCol({
          span: { xs: 8, sm: 8, md: 4, lg: 4 },
        }) {
          Column() {
            if (this.flagN === 1) {
              // Single face
              Text(globalThis.title)
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .margin({ top: $r('app.float.content_padding_top') })
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .fontWeight(FontWeight.Medium)
              if (this.prompt === Constants.FACE_SUCCESS) {
                Image($r("app.media.right_faceID"))
                  .margin({
                    top: $r('app.float.digitalpsd_passwdmask_height'),
                    bottom: $r('app.float.digitalpsd_passwdmask_height')
                  })
                  .width($r('app.float.image_size'))
                  .height($r('app.float.image_size'))
                  .colorBlend($r('sys.color.ohos_id_color_activated'))
                Text(this.prompt).fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_secondary'))
              } else if (this.prompt === Constants.RESET_AGAIN) {
                Image($r("app.media.error_faceID"))
                  .margin({
                    top: $r('app.float.digitalpsd_passwdmask_height'),
                    bottom: $r('app.float.digitalpsd_passwdmask_height')
                  })
                  .width($r('app.float.image_size'))
                  .height($r('app.float.image_size'))
                  .colorBlend($r('sys.color.ohos_id_color_activated'))
                Text(this.prompt).fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_warning'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .onClick(() => {
                    this.checkPassword(Constants.NOTICE_TYPE_FACE)
                  })
              } else if (this.prompt === Constants.FINGER_LOCK) {
                Image($r("app.media.error_faceID"))
                  .margin({
                    top: $r('app.float.digitalpsd_passwdmask_height'),
                    bottom: $r('app.float.digitalpsd_passwdmask_height')
                  })
                  .width($r('app.float.image_size'))
                  .height($r('app.float.image_size'))
                  .colorBlend($r('sys.color.ohos_id_color_activated'))
                Text(this.prompt).fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_warning'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
              } else if (this.prompt === Constants.FACE_DOING) {
                Image($r("app.media.error_faceID"))
                  .margin({
                    top: $r('app.float.digitalpsd_passwdmask_height'),
                    bottom: $r('app.float.digitalpsd_passwdmask_height')
                  })
                  .width($r('app.float.image_size'))
                  .height($r('app.float.image_size'))
                  .colorBlend($r('sys.color.ohos_id_color_activated'))
                Text(this.prompt).fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
              }
              Row() {
                Column() {
                  Button($r("app.string.unified_authwidget_cancel"), { stateEffect: true })
                    .margin({ left: $r('app.float.content_padding') })
                    .width(Constants.NINETY_PERCENT_WIDTH)
                    .height($r('app.float.btn_height'))
                    .fontSize($r("sys.float.ohos_id_text_size_button1"))
                    .fontColor($r("sys.color.ohos_id_color_text_primary_activated"))
                    .fontWeight(FontWeight.Medium)
                    .backgroundColor(Color.Transparent)
                    .onClick(() => {
                      globalThis.session?.terminateSelf();
                      this.cancel()
                    })
                }.width(Constants.HALF_CONTAINER_WIDTH)

                Divider()
                  .vertical(true)
                  .height($r('app.float.digitalpsd_passwdmask_height'))
                  .color($r("sys.color.ohos_id_color_list_separator"))
                  .width($r('app.float.divider_width'))
                Column() {
                  Button($r('app.string.unified_authwidget_usepwd'))
                    .margin({ right: $r('app.float.content_padding') })
                    .width(Constants.NINETY_PERCENT_WIDTH)
                    .height($r('app.float.btn_height'))
                    .fontSize($r("sys.float.ohos_id_text_size_button1"))
                    .fontColor($r("sys.color.ohos_id_color_text_primary_activated"))
                    .fontWeight(FontWeight.Medium)
                    .backgroundColor(Color.Transparent)
                    .onClick(() => {
                      this.flagN = 5
                      LogUtils.i(TAG, "flagN: " + this.flagN)
                    })
                }.width(Constants.HALF_CONTAINER_WIDTH)

              }
              .height($r('app.float.btn_height'))
              .margin({ top: $r("app.float.element_margin"), bottom: $r('app.float.content_padding') })
            }
            if (this.flagN === 2) {
              // The first form of facial fingerprint password
              Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                Image($r("app.media.ic_public_cancel"))
                  .width($r('app.float.digitalpsd_passwdmask_height'))
                  .height($r('app.float.digitalpsd_passwdmask_height'))
                  .margin({
                    top: $r('app.float.digitalpsd_passwdmask_height'),
                    left: $r('app.float.digitalpsd_passwdmask_height')
                  })
                  .onClick(() => {
                    globalThis.session?.terminateSelf();
                    this.cancel()
                    this.textValue = ""
                  })
                Button($r('app.string.unified_authwidget_usepwd'))
                  .backgroundColor(Color.White)
                  .height($r('app.float.digitalpsd_passwdmask_height'))
                  .padding(0)
                  .margin({
                    top: $r('app.float.digitalpsd_passwdmask_height'),
                    right: $r('app.float.digitalpsd_passwdmask_height')
                  })
                  .fontColor($r('sys.color.ohos_id_color_activated'))
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight(FontWeight.Medium)
                  .onClick(() => {
                    this.flagN = 5
                  })
              }

              Image($r("app.media.error_faceID"))
                .width($r('app.float.image_small'))
                .height($r('app.float.image_small'))
                .margin({ top: $r('app.float.content_padding'), bottom: $r('app.float.content_padding') })
                .colorBlend($r('sys.color.ohos_id_color_activated'))
              Text(globalThis.title).fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontColor($r('sys.color.ohos_id_color_text_primary'))

              if (this.prompt === Constants.RESET_AGAIN) {
                Text(this.prompt)
                  .margin({ top: $r("app.float.element_margin") })
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_warning'))
                  .onClick(() => {
                    this.checkPassword(Constants.NOTICE_TYPE_FACE)
                  })
              } else if (this.prompt === Constants.FINGER_LOCK) {
                Text(this.prompt)
                  .margin({ top: $r("app.float.element_margin") })
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_warning'))
              } else if (this.prompt === Constants.FACE_LOCK) {
                Text(this.prompt)
                  .margin({ top: $r("app.float.element_margin") })
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_warning'))
              } else {
                Text(this.prompt)
                  .margin({ top: $r("app.float.element_margin") })
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_secondary'))
              }
              Image($r("app.media.ic_blue_fingerprint"))
                .width($r('app.float.image_medium'))
                .height($r('app.float.image_medium'))
                .margin({
                  top: $r('app.float.digitalpsd_passwdmask_height'),
                  bottom: $r('app.float.digitalpsd_passwdmask_height')
                })
                .onClick(() => {
                  if (this.prompt !== Constants.FINGER_LOCK) {
                    this.checkPassword('fingerprint')
                  }
                })
            }
            if (this.flagN === 3) {
              // Facial fingerprint password, second form
              Image($r("app.media.error_faceID"))
                .width($r('app.float.image_small'))
                .height($r('app.float.image_small'))
                .margin({ top: $r('app.float.content_padding_top'), bottom: $r('app.float.content_padding') })
                .colorBlend($r('sys.color.ohos_id_color_activated'))
              Text(globalThis.title).fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontColor($r('sys.color.ohos_id_color_text_primary'))

              Image($r("app.media.ic_blue_fingerprint"))
                .width($r('app.float.image_medium'))
                .height($r('app.float.image_medium'))
                .margin({ top: $r('app.float.content_padding') })
                .onClick(() => {
                  if (this.prompt !== Constants.FINGER_LOCK) {
                    this.checkPassword('fingerprint')
                  }
                })
              Text($r('app.string.unified_authwidget_hint_inscreen_fp'))
                .margin({ top: $r('app.float.content_padding') })
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
              Row() {
                Column() {
                  Button($r("app.string.unified_authwidget_cancel"), { stateEffect: true })
                    .margin({ left: $r('app.float.content_padding') })
                    .width(Constants.NINETY_PERCENT_WIDTH)
                    .height($r('app.float.btn_height'))
                    .fontSize($r("sys.float.ohos_id_text_size_button1"))
                    .fontColor($r("sys.color.ohos_id_color_text_primary_activated"))
                    .fontWeight(FontWeight.Medium)
                    .backgroundColor(Color.Transparent)
                    .onClick(() => {
                      globalThis.session?.terminateSelf();
                      this.cancel()
                      this.textValue = ""
                    })
                }.width(Constants.HALF_CONTAINER_WIDTH)

                Divider()
                  .vertical(true)
                  .height($r('app.float.digitalpsd_passwdmask_height'))
                  .color($r("sys.color.ohos_id_color_list_separator"))
                  .width($r('app.float.divider_width'))
                Column() {
                  Button($r('app.string.unified_authwidget_usepwd'))
                    .margin({ right: $r('app.float.content_padding') })
                    .width(Constants.NINETY_PERCENT_WIDTH)
                    .height($r('app.float.btn_height'))
                    .fontSize($r("sys.float.ohos_id_text_size_button1"))
                    .fontColor($r("sys.color.ohos_id_color_text_primary_activated"))
                    .fontWeight(FontWeight.Medium)
                    .backgroundColor(Color.Transparent)
                    .onClick(() => {
                      globalThis.session?.terminateSelf();
                      this.cancel()
                    })

                }.width(Constants.HALF_CONTAINER_WIDTH)

              }
              .height($r('app.float.btn_height'))
              .margin({ top: $r("app.float.element_margin"), bottom: $r('app.float.content_padding') })
            }
            if (this.flagN === 4) {
              // Password 32-bit
              Column() {
                Pwd({
                  type: $type,
                  textValue: $textValue,
                  inputValue: $inputValue,
                  isEdit: $isEdit,
                })
                Row() {
                  Column() {
                    Button($r("app.string.unified_authwidget_cancel"), { stateEffect: true })
                      .margin({ left: $r('app.float.content_padding') })
                      .width(Constants.NINETY_PERCENT_WIDTH)
                      .height($r('app.float.btn_height'))
                      .fontSize($r("sys.float.ohos_id_text_size_button1"))
                      .fontColor($r("sys.color.ohos_id_color_text_primary_activated"))
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor(Color.Transparent)
                      .onClick(() => {
                        globalThis.session?.terminateSelf();
                        this.cancel()
                        this.textValue = ""
                      })
                  }.width(Constants.HALF_CONTAINER_WIDTH)

                  Divider()
                    .vertical(true)
                    .height($r('app.float.digitalpsd_passwdmask_height'))
                    .color($r("sys.color.ohos_id_color_list_separator"))
                    .width($r('app.float.divider_width'))
                  Column() {
                    Button($r('app.string.unified_authwidget_confirm'))
                      .margin({ right: $r('app.float.content_padding') })
                      .width(Constants.NINETY_PERCENT_WIDTH)
                      .height($r('app.float.btn_height'))
                      .fontSize($r("sys.float.ohos_id_text_size_button1"))
                      .fontColor($r("sys.color.ohos_id_color_text_primary_activated"))
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor(Color.Transparent)
                      .onClick(async (e) => {
                        // check callback
                        let userAuthWidgetMgr;
                        try {
                          let that = this;
                          LogUtils.d(TAG, 'getUserAuthWidgetMgr start');
                          userAuthWidgetMgr = await userAuth.getUserAuthWidgetMgr(1);
                          userAuthWidgetMgr.on('command', {
                            callback: function (result) {
                              LogUtils.d(TAG, 'getUserAuthWidgetMgr onCommand result: ' + JSON.stringify(result));
                              // check fail callback
                              const cmdData = JSON.parse(result?.cmdData)
                              if (cmdData?.cmd?.[0]?.payload?.result !== Constants.USER_AUTH_WIDGET_MGR_SUCCESS) {
                                // frequency
                                const frequency = cmdData?.cmd?.[0]?.payload?.remainAttempts;
                                LogUtils.d(TAG, 'frequency', frequency)
                                if (frequency) {
                                  that.inputValue = Constants.ERROR_PASSWORD;
                                  that.textValue = ''
                                  if (frequency < 4) {
                                    that.inputValue = `密码错误，还可尝试${frequency}次`;
                                  }
                                }
                                // countdown
                                const time = cmdData?.cmd?.[0]?.payload?.lockoutDuration;
                                if (frequency === 0 && time) {
                                  that.countTime(time);
                                  that.isEdit = false;
                                }
                              } else {
                                // check success
                                that.controller.close();
                              }
                            }
                          });
                          LogUtils.d(TAG, 'getUserAuthWidgetMgr success: ' + JSON.stringify(userAuthWidgetMgr));
                        } catch (error) {
                          LogUtils.e(TAG, 'getUserAuthWidgetMgr catch error: ' + JSON.stringify(error));
                        }
                        // check
                        try {
                          const eventData = {
                            // widgetContextId from onCreate
                            widgetContextId: 123456,
                            event: 'EVENT_AUTH_TYPE_READY',
                            version: '1',
                            payload: {
                              type: ['pin']
                            }
                          };
                          const jsonEventData = JSON.stringify(eventData);
                          LogUtils.d(TAG, 'sendNotice start eventData: ' + jsonEventData);
                          await userAuth.sendNotice(1, jsonEventData);
                          LogUtils.d(TAG, 'sendNotice success');
                        } catch (error) {
                          LogUtils.e(TAG, 'sendNotice catch error: ' + JSON.stringify(error));
                        }
                      })
                  }.width(Constants.HALF_CONTAINER_WIDTH)
                }
                .height($r('app.float.btn_height'))
                .margin({ top: $r("app.float.element_margin"), bottom: $r('app.float.content_padding') })
              }

            }
            if (this.flagN === 5) {
              // Password 6-bit
              Column() {
                SixPwd({
                  textValue: $textValue,
                  inputValue: $inputValue,
                  isEdit: $isEdit,
                  controllerFlag: $controllerFlag
                })
                Button($r('app.string.unified_authwidget_cancel'), { stateEffect: true })
                  .onClick(() => {
                    globalThis.session?.terminateSelf();
                    this.cancel()
                    this.textValue = ""
                  })
                  .backgroundColor(Color.Transparent)
                  .height($r('app.float.btn_height'))
                  .width(Constants.HALF_CONTAINER_WIDTH)
                  .margin({ top: $r("app.float.element_margin"), bottom: $r('app.float.content_padding') })
                  .fontSize($r('sys.float.ohos_id_text_size_button1'))
                  .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                  .fontWeight(FontWeight.Medium)
              }
            }
            if (this.flagN === 6) {
              // Single face
              Text(globalThis.title)
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .margin({ top: $r('app.float.content_padding_top') })
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .fontWeight(FontWeight.Medium)
              if (this.prompt === Constants.FACE_SUCCESS) {
                Image($r("app.media.right_faceID"))
                  .margin({
                    top: $r('app.float.digitalpsd_passwdmask_height'),
                    bottom: $r('app.float.digitalpsd_passwdmask_height')
                  })
                  .width($r('app.float.image_size'))
                  .height($r('app.float.image_size'))
                  .colorBlend($r('sys.color.ohos_id_color_activated'))
                Text(this.prompt).fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_secondary'))
              } else if (this.prompt === Constants.RESET_AGAIN) {
                Image($r("app.media.error_faceID"))
                  .margin({
                    top: $r('app.float.digitalpsd_passwdmask_height'),
                    bottom: $r('app.float.digitalpsd_passwdmask_height')
                  })
                  .width($r('app.float.image_size'))
                  .height($r('app.float.image_size'))
                  .colorBlend($r('sys.color.ohos_id_color_activated'))
                Text(this.prompt).fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_warning'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .onClick(() => {
                    if (this.prompt === Constants.RESET_AGAIN) {
                      this.checkPassword(Constants.NOTICE_TYPE_FACE)
                    }
                  })
              } else if (this.prompt === Constants.FACE_DOING) {
                Image($r("app.media.error_faceID"))
                  .margin({
                    top: $r('app.float.digitalpsd_passwdmask_height'),
                    bottom: $r('app.float.digitalpsd_passwdmask_height')
                  })
                  .width($r('app.float.image_size'))
                  .height($r('app.float.image_size'))
                  .colorBlend($r('sys.color.ohos_id_color_activated'))
                Text(this.prompt).fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
              }
              Row() {
                Column() {
                  Button($r('app.string.unified_authwidget_cancel'), { stateEffect: true })
                    .onClick(() => {
                      globalThis.session?.terminateSelf();
                      this.cancel()
                    })
                    .backgroundColor(Color.Transparent)
                    .height($r('app.float.btn_height'))
                    .width(Constants.FULL_CONTAINER_WIDTH)
                    .fontSize($r('sys.float.ohos_id_text_size_button1'))
                    .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                    .fontWeight(FontWeight.Medium)
                }
              }
              .height($r('app.float.btn_height'))
              .padding({ left: $r('app.float.content_padding'), right: $r('app.float.content_padding') })
              .margin({ top: $r("app.float.element_margin"), bottom: $r('app.float.content_padding') })
            }
          }
          .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_dialog'))
          .margin({
            left: ($r('sys.float.ohos_id_dialog_margin_start')),
            right: ($r('sys.float.ohos_id_dialog_margin_end')),
            bottom: ($r('sys.float.ohos_id_dialog_margin_bottom'))
          })
        }
      }
    }
    .height(Constants.FULL_CONTAINER_HEIGHT)
    .justifyContent(FlexAlign.End)
    .backgroundColor(Color.Transparent)
  }
}
