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
import LogUtils from '../../common/utils/LogUtils';
import Constants from '../../common/vm/Constants';
import TimeUtils from '../utils/TimeUtils';

const TAG = 'SixPwd';

@Component
export default struct SixPwd {
  @Link textValue: string;
  @Link inputValue: string;
  @Link isEdit: boolean;
  @Link controllerFlag: boolean;
  cancel: () => void;
  confirm: () => void;

  countTime(freezingTime) {
    const TRY_AGAIN = '后重试';
    let promptText: string = '';
    let freezingMillisecond = freezingTime;
    if (freezingMillisecond > 0) {
      promptText = TimeUtils.getFreezingTimeNm(freezingMillisecond);
      promptText += TRY_AGAIN;
      setTimeout(this.countTime.bind(this), 1000, freezingTime - 1000);
    } else {
      promptText = Constants.INPUT_PASSWORD
      this.isEdit = true;
    }
    this.inputValue = promptText;
  }

  build() {
    Column() {
      Text(globalThis.title)
        .margin({ top: $r('app.float.content_padding_top') })
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .fontWeight(FontWeight.Medium)
      Column() {
        Stack() {
          TextInput({ placeholder: '', text: this.textValue })
            .onChange(async (value: string) => {
              this.textValue = value
              if (value.length === 6) {
                // check callback
                let userAuthWidgetMgr;
                try {
                  let that = this;
                  LogUtils.d(TAG, 'getUserAuthWidgetMgr start');
                  userAuthWidgetMgr = await userAuth.getUserAuthWidgetMgr(1);
                  userAuthWidgetMgr.on('command', {
                    callback: function (result) {
                      LogUtils.d(TAG, 'getUserAuthWidgetMgr result: ' + JSON.stringify(result));
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
                        that.controllerFlag = true;
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
              }
            })
            .backgroundImageSize(ImageSize.Auto)
            .enabled(this.isEdit)
            .maxLength(6)
            .visibility(Visibility.Visible)
            .opacity(0)
            .caretColor('transparent')
          List({ space: 4 }) {
            ForEach(['', '', '', '', '', ''], (item, index) => {
              ListItem() {
                Button()
                  .border({
                    color: Color.Black,
                    style: BorderStyle.Solid,
                    width: this.textValue.length !== 0 && index < this.textValue.length ? '6vp' : 1
                  })
                  .type(ButtonType.Circle)
                  .backgroundColor(Color.White)
                  .width($r('app.float.input_btn_size'))
                  .height($r('app.float.input_btn_size'))
                  .borderRadius($r('app.float.input_btn_size'))
                  .margin(index > 0 ? { left: $r('app.float.input_btn_padding_around') } : {})
                  .focusable(true)
              }
            }, item => item)
          }
          .listDirection(Axis.Horizontal)
          .height($r('app.float.input_btn_size'))
        }
      }
      .margin({ top: $r('app.float.content_padding') })
      .padding({ top: $r('app.float.input_btn_padding_up_down'), bottom: $r('app.float.input_btn_padding_up_down') })

      Text(this.inputValue)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .margin({ top: $r("app.float.element_margin") })
        .fontColor($r('sys.color.ohos_id_color_warning'))
    }
  }
}