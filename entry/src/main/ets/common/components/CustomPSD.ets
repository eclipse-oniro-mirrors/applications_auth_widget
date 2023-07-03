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

import screen from '@ohos.screen';
import userAuth from '@ohos.userIAM.userAuth';
import Constants from '../../common/vm/Constants';
import LogUtils from '../utils/LogUtils';
import TimeUtils from '../utils/TimeUtils';
import NumKeyBoard from './NumkeyBoard'

const TAG = "CustomPSD";

const CONTROL_TYPE_SIX_NUMBER = 1;
const CONTROL_TYPE_ARBITRARY_NUMBER = 2;

interface ControlType {
  isSixPassword?: boolean,
  isLandscape: boolean,
  jumpFinger: boolean,
  type: number // 1:six number 2:arbitrary number 3:arbitrary character
  isShowFace: boolean,
  isShowFinger: boolean,
}

interface KeyboardType {
  index: number
  row1: string | Resource
  row2?: string
  value?: number
  bkg?: boolean
}

@Component
export default struct CustomPSD {
  @Link textValue: string
  @Link themeType: number
  @Link type: number
  @Link controllerFlag: boolean
  @Link authType: Array<userAuth.UserAuthType>;
  @State lock: number = 0
  @State screenClass: object = {}
  @StorageLink('cueWord') cueWord: string = Constants.INPUT_PASSWORD
  @StorageLink('passwordArr') passwordArr: string[] = ['', '', '', '', '', '']
  @StorageLink('passwordArrNumber') passwordArrNumber: string[] = []
  @State passwordObj: string = ''
  numKeyboard: KeyboardType[] = Constants.NUM_KEY_BOARD;
  @State prompt: string = Constants.INPUT_PASSWORD;
  @State fingerText: string = Constants.INPUT_FINGER;
  @StorageLink('screenLockDirection') screenLockDirection: number = 1
  @State controlType: ControlType = {
    type: CONTROL_TYPE_SIX_NUMBER, // 1:six number 2:arbitrary number 3:arbitrary character
    jumpFinger: false,
    isLandscape: false,
    isSixPassword: true,
    isShowFace: this.authType.includes(2),
    isShowFinger: this.authType.includes(4)
  }
  controller: CustomDialogController
  cancel: () => void
  confirm: () => void

  queryScreenInfo() {
    try {
      screen.getAllScreens((err, data) => {
        if (err.code) {
          LogUtils.e(TAG, 'Failed to get all screens. Cause: ' + JSON.stringify(err));
          return;
        }
        this.screenClass = data[0];
        LogUtils.d(TAG, 'success to get all screens. Data: ' + JSON.stringify(this.screenClass));
      });
    } catch (exception) {
      LogUtils.e(TAG, 'getAllScreens catch exception: ' + exception);
    }
  }

  // face or finger
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
            case 'pin':
              if (cmdData?.cmd?.[0]?.payload?.result !== Constants.USER_AUTH_WIDGET_MGR_SUCCESS) {
                // frequency
                const frequency = cmdData?.cmd?.[0]?.payload?.remainAttempts;
                that.clearPassword()
                if (frequency) {
                  that.prompt = Constants.ERROR_PASSWORD;
                  if (frequency < 4) {
                    that.prompt = `密码错误，还可尝试${frequency}次`;
                  }
                }
                // countdown
                const time = cmdData?.cmd?.[0]?.payload?.lockoutDuration;
                if (frequency === 0 && time) {
                  that.lock = 1;
                  that.countdown(time);
                }

                if (!frequency && !time) {
                  that.lock = 1;
                }
              } else {
                // check success
                that.lock = 0;
                globalThis.session?.terminateSelf();
              }
              break;
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
                globalThis.session?.terminateSelf();
              }
              break;
            case 'fingerprint':
              if (cmdData?.cmd?.[0]?.payload?.result !== 0) {
                // frequency
                const frequency = cmdData?.cmd?.[0]?.payload?.remainAttempts;
                if (frequency) {
                  that.prompt = Constants.AGAIN_FINGER;
                  that.fingerText = Constants.AGAIN_FINGER;
                }
                if (frequency === 0) {
                  that.prompt = Constants.FINGER_LOCK;
                  that.fingerText = Constants.FINGER_LOCK;
                }
                // countdown

              } else {
                // check success
                that.lock = 0;
                globalThis.session?.terminateSelf();
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

  // pin
  pinPassword() {
    // check callback
    let userAuthWidgetMgr;
    try {
      let that = this;
      userAuthWidgetMgr = userAuth.getUserAuthWidgetMgr(1);
      LogUtils.d(TAG, 'pinPassword getUserAuthWidgetMgr success');
      userAuthWidgetMgr.on('command', {
        callback: function (result) {

          LogUtils.d(TAG, 'pinPassword getUserAuthWidgetMgr onCommand result: ' + JSON.stringify(result));
          const cmdData = JSON.parse(result?.cmdData);
          const authType = cmdData?.cmd?.[0]?.payload?.type;
          switch (authType) {
            case 'pin':
              if (cmdData?.cmd?.[0]?.payload?.result !== Constants.USER_AUTH_WIDGET_MGR_SUCCESS) {
                // frequency
                const frequency = cmdData?.cmd?.[0]?.payload?.remainAttempts;
                that.clearPassword()
                if (frequency) {
                  that.prompt = Constants.ERROR_PASSWORD;
                  if (frequency < 4) {
                    that.prompt = `密码错误，还可尝试${frequency}次`;
                  }
                }
                // countdown
                const time = cmdData?.cmd?.[0]?.payload?.lockoutDuration;
                if (frequency === 0 && time) {
                  that.lock = 1;
                  that.countdown(time);
                }

                if (!frequency && !time) {
                  that.lock = 1;
                }
              } else {
                // check success
                that.lock = 0;
                globalThis.session?.terminateSelf();
              }
              break;
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
                globalThis.session?.terminateSelf();
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
                that.lock = 0;
                globalThis.session?.terminateSelf();
              }
            default:
              break;
          }
        }
      });
      LogUtils.d(TAG, 'pinPassword getUserAuthWidgetMgr success: ' + JSON.stringify(userAuthWidgetMgr));
    } catch (error) {
      LogUtils.e(TAG, 'pinPassword getUserAuthWidgetMgr catch error: ' + JSON.stringify(error));
    }

    // check
    try {
      const eventData = {
        // widgetContextId from onCreate
        widgetContextId: 123456,
        event: 'EVENT_AUTH_TYPE_READY',
        version: '1',
        payload: {
          type: [Constants.NOTICE_TYPE_PIN]
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

  // start
  getPosition() {

    // check callback
    let userAuthWidgetMgr;
    try {
      let that = this;
      userAuthWidgetMgr = userAuth.getUserAuthWidgetMgr(1);
      LogUtils.d(TAG, 'pinPassword getUserAuthWidgetMgr success');
      userAuthWidgetMgr.on('command', {
        callback: function (result) {

          LogUtils.d(TAG, 'pinPassword getUserAuthWidgetMgr onCommand result: ' + JSON.stringify(result));
          const cmdData = JSON.parse(result?.cmdData);
          const authType = cmdData?.cmd?.[0]?.payload?.type;
          switch (authType) {
            case 'pin':
              if (cmdData?.cmd?.[0]?.payload?.result !== Constants.USER_AUTH_WIDGET_MGR_SUCCESS) {
                // frequency
                const frequency = cmdData?.cmd?.[0]?.payload?.remainAttempts;
                that.clearPassword()
                if (frequency) {
                  that.prompt = Constants.ERROR_PASSWORD;
                  if (frequency < 4) {
                    that.prompt = `密码错误，还可尝试${frequency}次`;
                  }
                }
                // countdown
                const time = cmdData?.cmd?.[0]?.payload?.lockoutDuration;
                if (frequency === 0 && time) {
                  that.lock = 1;
                  that.countdown(time);
                }

                if (!frequency && !time) {
                  that.lock = 1;
                }
              } else {
                // check success
                that.lock = 0;
                globalThis.session?.terminateSelf();
              }
              break;
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
                globalThis.session?.terminateSelf();
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
                that.lock = 0;
                globalThis.session?.terminateSelf();
              }
            default:
              break;
          }
        }
      });
      LogUtils.d(TAG, 'pinPassword getUserAuthWidgetMgr success: ' + JSON.stringify(userAuthWidgetMgr));
    } catch (error) {
      LogUtils.e(TAG, 'pinPassword getUserAuthWidgetMgr catch error: ' + JSON.stringify(error));
    }
    try {
      const eventData = {
        // widgetContextId from onCreate
        widgetContextId: 123456,
        event: 'CMD_NOTIFY_AUTH_START',
        version: Constants.NOTICE_VERSION,
        payload: {
          type: [Constants.NOTICE_TYPE_FINGER]
        }
      };
      const jsonEventData = JSON.stringify(eventData);
      LogUtils.d(TAG, 'getPosition sendNotice start eventData: ' + jsonEventData);
      userAuth.sendNotice(userAuth.NoticeType.WIDGET_NOTICE, jsonEventData);
      LogUtils.d(TAG, 'getPosition sendNotice success');
    } catch (error) {
      LogUtils.e(TAG, 'getPosition sendNotice catch error: ' + JSON.stringify(error));
    }
  }

  aboutToAppear() {
    AppStorage.SetOrCreate('passwordArr', ['', '', '', '', '', '']);
    this.queryScreenInfo()
    this.getPosition()
    if (this.controlType.isShowFace) {
      this.checkPassword(Constants.NOTICE_TYPE_FACE)
    }
  }

  clearPassword() {
    this.passwordArr = [];
    this.passwordArrNumber = [];
    this.passwordArr = ['', '', '', '', '', ''];
    this.numKeyboard[11].value = Constants.GO_BACK;
    this.updateStorage(() => {
    })
  }

  aboutToDisappear() {
    this.clearPassword()
  }

  onPageShow() {
  }

  countdown(freezingTime) {
    const TRY_AGAIN = "后重试"
    let promptText: string = '';
    let freezingMillisecond = freezingTime;
    if (freezingMillisecond > 0) {
      promptText = TimeUtils.getFreezingTimeNm(freezingMillisecond);
      promptText += TRY_AGAIN;
      setTimeout(this.countdown.bind(this), Constants.INTERVAL, freezingTime - 1000)
    } else {
      promptText = Constants.INPUT_PASSWORD;
      this.clearPassword()
      this.lock = 0;
    }
    this.prompt = promptText;
  }

  updateStorage(callback) {
    AppStorage.SetOrCreate('passwordArr', this.passwordArr);
    AppStorage.SetOrCreate('numKeyboard', this.numKeyboard);
    callback()
  }

  build() {
    if (!this.controlType.jumpFinger) {
      Column() {
        Column() {
          if (this.lock === 1) {
            Text($r('app.string.unified_authwidget_locked'))
              .margin({ bottom: '16vp' })
              .fontColor(this.themeType === Constants.THEME_TYPE_WHITE
                ? $r('sys.color.ohos_id_color_text_primary')
                : $r('sys.color.ohos_id_color_text_primary_contrary'))
              .fontSize($r('sys.float.ohos_id_text_size_headline6'))
              .fontWeight(FontWeight.Medium)
          }
          if (this.controlType.isShowFace) {
            if (this.themeType === Constants.THEME_TYPE_GAUSSIAN_BLUR) {
              Image($r("app.media.white_faceID"))
                .width('30vp')
                .height('30vp')
                .margin({ bottom: '16vp' })
                .onClick(() => {
                  if (this.prompt !== Constants.FACE_LOCK && this.prompt !== Constants.FINGER_LOCK) {
                    this.checkPassword(Constants.NOTICE_TYPE_FACE)
                  }
                })
            }
            if (this.themeType === Constants.THEME_TYPE_WHITE) {
              Image($r("app.media.error_faceID"))
                .width('30vp')
                .height('30vp')
                .margin({ bottom: '16vp' })
                .visibility(Visibility.Visible)
                .colorBlend($r('sys.color.ohos_id_color_activated'))
            }
          }
          Text(this.prompt)
            .fontSize(this.cueWord === Constants.INPUT_PASSWORD
              ? $r('sys.float.ohos_id_text_size_body1')
              : $r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.themeType === Constants.THEME_TYPE_WHITE
              ? $r('sys.color.ohos_id_color_text_primary')
              : $r('sys.color.ohos_id_color_text_secondary_contrary'))
            .margin({ bottom: "8vp" })
            .textAlign(TextAlign.Center)
            .textOverflow({ overflow: TextOverflow.None })
            .height('20vp')
            .onClick(() => {
              if (this.prompt === Constants.RESET_AGAIN) {
                this.checkPassword(Constants.NOTICE_TYPE_FACE)
              }
            })

          Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
            if (this.lock === 0) {
              if (this.controlType.type === CONTROL_TYPE_SIX_NUMBER) {
                List({ space: Constants.DIGITALPSD_IC_DIAMETER }) {
                  ForEach(this.passwordArr, (item) => {
                    if ((!item || item === '') && item !== 0) {
                      ListItem() {
                        Button()
                          .border({
                            color: this.themeType === Constants.THEME_TYPE_WHITE ? Color.Black : Color.White,
                            style: BorderStyle.Solid,
                            width: 1
                          })
                          .borderRadius('12vp')
                          .width("12vp")
                          .height("12vp")
                          .type(ButtonType.Circle)
                          .backgroundColor(Color.Transparent)

                      }
                      .margin({ left: '5vp', right: '5vp' })
                    } else {
                      ListItem() {
                        Button()
                          .borderRadius('12vp')
                          .width("12vp")
                          .height("12vp")
                          .type(ButtonType.Circle)
                          .backgroundColor(this.themeType === Constants.THEME_TYPE_WHITE ? Color.Black : Color.White)
                      }
                      .margin({ left: '5vp', right: '5vp' })
                    }
                  })
                }
                .listDirection(Axis.Horizontal)
                .height("12vp")

              } else if (this.controlType.type === CONTROL_TYPE_ARBITRARY_NUMBER || this.type === Constants.TYPE_SCREEN_ARBITRARY_NUMBER) {
                Stack() {
                  TextInput({ placeholder: '', text: this.passwordArrNumber.join('') })
                    .width('100%')
                    .onChange(async (value: string) => {
                      this.passwordArrNumber = value.replace(/[^\d]/g, '').split('');
                    })
                    .onSubmit(async (enterKey: EnterKeyType) => {
                      let str = this.passwordArrNumber.toString()
                      this.textValue = str.replace(/,/g, '')
                      if (this.passwordArrNumber.length < 4) {
                        return;
                      }

                      const strData = this.passwordArrNumber.toString()
                      this.textValue = strData.replace(/,/g, '')
                      this.pinPassword()

                    })
                    .type(InputType.Password)
                    .backgroundImageSize(ImageSize.Auto)
                    .visibility(Visibility.Visible)
                    .copyOption(CopyOptions.None)
                    .maxLength(32)

                }
              } else if (this.type === Constants.TYPE_SCREEN_ARBITRARY_CHAR) {
                TextInput({ text: this.passwordObj })
                  .height('40vp')
                  .type(InputType.Password)
                  .textAlign(TextAlign.Center)
                  .copyOption(CopyOptions.None)
                  .maxLength(32)
                  .onSubmit(async (enterKey: EnterKeyType) => {
                    // check callback
                    if (this.passwordObj.length < 4) {
                      return;
                    }
                    this.textValue = this.passwordObj
                    this.pinPassword()
                  })
                  .onChange((value: string) => {
                    this.passwordObj = value
                  })
              }
            }
          }
          .width(this.screenLockDirection === 1 ? $r('app.float.custompsd_input_width')
                                                : $r('app.float.custompsd_input_width_portrait'))
          .height('40vp')

          Button(($r('app.string.unified_authwidget_forgotpwd')), {
            type: ButtonType.Normal,
            stateEffect: true
          })
            .height('40vp')
            .backgroundColor(Color.Transparent)
            .fontColor(this.themeType === Constants.THEME_TYPE_WHITE
              ? $r('sys.color.ohos_id_color_text_primary_activated')
              : $r('sys.color.ohos_id_color_text_primary_contrary'))
            .fontSize($r('sys.float.ohos_id_text_size_button1'))
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              let str = this.passwordArrNumber.toString()
              this.textValue = str.replace(/,/g, '');
            })
        }

        Column() {
          if (this.lock === 0) {
            NumKeyBoard({
              themeType: $themeType,
              onKeyPress: (index, callback) => {
                let keyValue = this.numKeyboard[index].value;
                if (keyValue > 0 || keyValue === 0) {
                  const index = this.passwordArr.map(item => item).indexOf('')
                  if (index > -1) {
                    this.passwordArr[index] = keyValue + '';
                    this.numKeyboard[11].row1 = $r('app.string.unified_authwidget_delete');
                    this.numKeyboard[11].value = Constants.DEL_PWD;
                    if (index === 5) {
                      this.passwordArr[index] = keyValue + '';
                      if (this.passwordArr.join('').length < 6) {
                        return;
                      }
                      let str = this.passwordArr.toString()
                      this.textValue = str.replace(/,/g, '')
                      this.pinPassword()
                    }
                    this.updateStorage(callback);
                  }
                } else if (keyValue === Constants.DEL_PWD) {
                  const index = this.passwordArr.map(item => item).indexOf('')
                  if (index === -1) {
                    this.passwordArr[5] = ''
                  } else if (index === 1) {
                    this.passwordArr[index-1] = ''
                    this.numKeyboard[11].value = Constants.GO_BACK;
                    this.numKeyboard[11].row1 = Constants.TEXT_BACK;
                  } else {
                    this.passwordArr[index-1] = ''
                  }
                  this.updateStorage(callback);
                } else if (keyValue === Constants.GO_BACK) {
                  this.lock = 0;
                  this.clearPassword()
                  globalThis.session?.terminateSelf();
                } else if (keyValue === Constants.CALL_PHONE) {
                  if (this.passwordArr.join('').length < 6) {
                    return;
                  }

                  let str = this.passwordArr.toString()
                  this.textValue = str.replace(/,/g, '')
                  this.pinPassword()
                  this.updateStorage(callback);
                }
              }
            })
          } else {
            Text().height(Constants.FULL_CONTAINER_HEIGHT)
          }
        }
        .width(Constants.FULL_CONTAINER_WIDTH)
        .height('40%')

        Column() {
          if (this.controlType.isShowFinger && this.lock !== 1) {
            if (this.themeType === Constants.THEME_TYPE_WHITE) {
              Image($r("app.media.ic_blue_fingerprint")).width('40vp').height('40vp')
                .onClick(() => {
                  this.checkPassword(Constants.NOTICE_TYPE_FINGER)
                })
            }
            if (this.themeType === Constants.THEME_TYPE_GAUSSIAN_BLUR) {
              Image($r("app.media.finger_white")).width('24vp').height('24vp')
                .margin({ top: '12vp' })
                .onClick(() => {
                  LogUtils.d(TAG, 'screenClass success' + JSON.stringify(this.screenClass));
                  const screenInfo = JSON.parse(JSON.stringify(this.screenClass));
                  this.controlType.jumpFinger = true
                  this.controlType.isLandscape = screenInfo.orientation === 2

                })
            }
          }

        }.width('24vp')
        .height(this.controlType.isShowFinger ? '72vp' : '9%')
        .justifyContent(FlexAlign.Start)
      }
      .justifyContent(FlexAlign.End)
      .width(Constants.FULL_CONTAINER_WIDTH)
    } else if (!this.controlType.isLandscape) {
      Column() {
        Text(globalThis.title)
          .height('40vp')
          .fontColor(this.themeType === Constants.THEME_TYPE_WHITE
            ? $r('sys.color.ohos_id_color_text_primary')
            : $r('sys.color.ohos_id_color_text_primary_contrary'))
          .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
          .fontWeight(FontWeight.Medium)
        Text(this.fingerText)
          .height('40vp')
          .fontColor(this.themeType === Constants.THEME_TYPE_WHITE
            ? $r('sys.color.ohos_id_color_text_secondary')
            : $r('sys.color.ohos_id_color_text_primary_contrary'))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
        Image($r("app.media.ic_unlock_fingerprint")).width('60vp').height('60vp')
          .margin({ "top": "0.00px", "right": "0.00px", "bottom": '90vp', "left": "0.00px" })
          .onClick(() => {
            if (this.prompt !== Constants.FINGER_LOCK) {
              this.checkPassword(Constants.NOTICE_TYPE_FINGER)
            }
          })
        Button($r('app.string.unified_authwidget_cancel'), {
          type: ButtonType.Normal,
          stateEffect: true
        })
          .margin({ bottom: '25vp' })
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.controlType.jumpFinger = false
          })
      }.justifyContent(FlexAlign.End)
      .height('300vp')
      .width('100%')
    }
    else {
      Column() {
        Text(Constants.FINGER_Landscape)
          .height('40vp')
          .fontColor(this.themeType === Constants.THEME_TYPE_WHITE
            ? $r('sys.color.ohos_id_color_text_primary')
            : $r('sys.color.ohos_id_color_text_primary_contrary'))
          .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
          .fontWeight(FontWeight.Medium)

      }.justifyContent(FlexAlign.End)
      .height('300vp')
      .width('100%')
    }
  }
}