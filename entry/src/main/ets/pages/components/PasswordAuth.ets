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
import Pwd from '../../common/components/Pwd';
import SixPwd from '../../common/components/SixPwd';
import LogUtils from '../../common/utils/LogUtils';
import TimeUtils from '../../common/utils/TimeUtils';
import Constants from '../../common/vm/Constants';

const TAG = 'PasswordAuth';

let pinAuthManager;
let pinData = '';


@Component
export default struct PasswordAuth {
  // 0:six number 1:arbitrary character 2:arbitrary number
  @Link type: number;
  @State @Watch('onFlagChange') controllerFlag: boolean = false;
  @State @Watch('onTextValueChange') textValue: string = '';
  @State isEdit: boolean = true;
  // tip
  @State inputValue: string = ' ';
  controller: CustomDialogController;
  cancel: () => void;
  confirm: () => void;

  onFlagChange() {
    if (this.controllerFlag) {
      globalThis.session?.terminateSelf();
    }
  }

  onTextValueChange() {
    pinData = this.textValue;
  }

  aboutToAppear() {
    // register input
    try {
      LogUtils.d(TAG, 'aboutToAppear PINAuth start');
      pinAuthManager = new account_osAccount.PINAuth();
      pinAuthManager.registerInputer({
        onGetData: (authSubType, callback) => {
          let textEncoder = new util.TextEncoder();
          let uint8PW = textEncoder.encode(pinData);
          LogUtils.d(TAG, `aboutToAppear PINAuth onGetData pinData: ${pinData}, uint8PW: ${uint8PW}`);
          callback.onSetData(authSubType, uint8PW);
        }
      });
    } catch (error) {
      LogUtils.e(TAG, 'aboutToAppear PINAuth catch error: ' + JSON.stringify(error));
    }
  }

  aboutToDisappear() {
    pinAuthManager?.unregisterInputer?.()
  }

  countTime(freezingTime) {
    const TRY_AGAIN = '后重试';
    let promptText: string = '';
    let freezingMillisecond = freezingTime;
    if (freezingMillisecond > 0) {
      promptText = TimeUtils.getFreezingTimeNm(freezingMillisecond);
      promptText += TRY_AGAIN;
      setTimeout(this.countTime.bind(this), 1000, freezingTime - 1000);
    } else {
      promptText = Constants.INPUT_PASSWORD;
      this.isEdit = true;
    }
    this.inputValue = promptText;
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
            if (this.type !== Constants.TYPE_DIALOG_SIX_NUMBER) {
              // arbitrary input
              Column() {
                Pwd({
                  type: $type,
                  textValue: $textValue,
                  inputValue: $inputValue,
                  isEdit: $isEdit,
                })
                Row() {
                  Column() {
                    Button($r('app.string.cancel'), { stateEffect: true })
                      .margin({ left: $r('app.float.content_padding') })
                      .width('90%')
                      .height($r('app.float.btn_height'))
                      .fontSize($r('sys.float.ohos_id_text_size_button1'))
                      .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor(Color.Transparent)
                      .onClick(() => {
                        globalThis.session?.terminateSelf();
                        LogUtils.d(TAG, `globalThis.session` + JSON.stringify(globalThis.session) + globalThis.session.terminateSelf());
                        this.cancel();
                        this.textValue = '';
                        this.inputValue = ' ';
                      })
                  }.width('50%')

                  Divider()
                    .vertical(true)
                    .height($r('app.float.btn_height'))
                    .color($r('sys.color.ohos_id_color_list_separator'))
                    .width($r('app.float.divider_width'))
                  Column() {
                    Button($r('app.string.confirm'))
                      .onClick(async () => {
                        // check callback
                        let userAuthWidgetMgr;
                        try {
                          let that = this;
                          LogUtils.d(TAG, 'getUserAuthWidgetMgr start');
                          userAuthWidgetMgr = await userAuth.getUserAuthWidgetMgr(1);
                          // check callback
                          userAuthWidgetMgr.on('command', {
                            callback: function (result) {
                              LogUtils.d(TAG, 'getUserAuthWidgetMgr onCommand result: ' + JSON.stringify(result));
                              // fail
                              const cmdData = JSON.parse(result?.cmdData)
                              if (cmdData?.cmd?.[0]?.payload?.result !== Constants.USER_AUTH_WIDGET_MGR_SUCCESS) {
                                // frequency
                                const frequency = cmdData?.cmd?.[0]?.payload?.remainAttempts;
                                if (frequency) {
                                  that.inputValue = Constants.ERROR_PASSWORD;
                                  that.textValue = '';
                                  if (frequency < 4) {
                                    that.inputValue = `密码错误，还可尝试${frequency}次`;
                                  }
                                  return;
                                }
                                // countdown
                                const time = cmdData?.cmd?.[0]?.payload?.lockoutDuration;
                                if (frequency === 0 && time) {
                                  that.countTime(time);
                                  that.isEdit = false;
                                  that.textValue = '';
                                  return;
                                }
                                that.inputValue = Constants.ERROR_PASSWORD;
                                that.textValue = '';
                              } else {
                                // success
                                that.controller.close();
                              }
                            }
                          });
                          LogUtils.d(TAG, 'getUserAuthWidgetMgr success userAuthWidgetMgr: ' + JSON.stringify(userAuthWidgetMgr));
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
                      .enabled(this.textValue.length >= 4)
                      .margin({ right: $r('app.float.content_padding') })
                      .width('90%')
                      .height($r('app.float.btn_height'))
                      .fontSize($r('sys.float.ohos_id_text_size_button1'))
                      .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                      .opacity(this.textValue.length >= 4 ? 1 : $r('sys.float.ohos_fa_alpha_disabled'))
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor(Color.Transparent)
                  }.width('50%')
                }
                .height($r('app.float.btn_height'))
                .margin({ top: $r("app.float.element_margin"), bottom: $r('app.float.content_padding') })
              }
            } else {
              // six number
              Column() {
                SixPwd({
                  textValue: $textValue,
                  inputValue: $inputValue,
                  isEdit: $isEdit,
                  controllerFlag: $controllerFlag
                })
                Button($r('app.string.cancel'), { stateEffect: true })
                  .onClick(() => {
                    globalThis.session?.terminateSelf();
                    this.cancel()
                    this.textValue = ''
                    this.inputValue = ' '
                  })
                  .backgroundColor(Color.Transparent)
                  .height($r('app.float.btn_height'))
                  .width('50%')
                  .margin({ top: $r("app.float.element_margin"), bottom: $r('app.float.content_padding') })
                  .fontSize($r('sys.float.ohos_id_text_size_button1'))
                  .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                  .fontWeight(FontWeight.Medium)
              }
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
    .height('100%')
    .justifyContent(FlexAlign.End)
    .backgroundColor(Color.Transparent)
  }
}




