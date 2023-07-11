/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License")
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

import { Driver, ON } from '@ohos.UiTest';
import { beforeAll, describe, expect, it } from '@ohos/hypium';

const delayTime: number = 1000;

export default function FaceAuthTest() {
  describe('faceAuthTest', function () {
    beforeAll(async function () {
      const data = {
        "cmd": [{
          "event": "CMD_NOTIFY_AUTH_START", "payload": {
            "lockoutDuration": 0, "remainAttempts": 5, "type": "face", "sensorInfo": ""
          }, "version": "1"
        }],
        "title": "",
        "type": ["face"],
        "widgetContextId": 16850018705910348000,
        "windowModeType": "DIALOG_BOX"
      };
      globalThis.wantParams = data;
    })

    it('promptText_resetPin_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('promptTextResetPinFaceAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('cancelBtn_pin_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('cancelBtnPinFaceAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('usePwd_pin_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('usePwdPinFaceAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('cancelImg_all_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('cancelImgAllFaceAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('usePwdBtn_all_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('usePwdBtnAllFaceAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('resetPromptText_all_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('resetPromptTextAllFaceAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('blueFingerprintImg_all_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('blueFingerprintImgAllFaceAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('unlockFingerprintImg_customPwd_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('unlockFingerprintImgCustomPwd'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('errFaceImg_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('errFaceImgFaceAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('blueFingerprintImg_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('blueFingerprintImgFaceAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('cancelBtn_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('cancelBtnFaceAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('usePwdBtn_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('usePwdBtnFaceAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('cancelBtn_mixedPin_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('cancelBtnMixedPinFaceAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('okBtn_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('okBtnFaceAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('cancelBtn_sixPin_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('cancelBtnSixPinFaceAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('promptText_reset_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('promptTextResetFaceAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })
  })
}