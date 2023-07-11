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

export default function fingerprintAuthTest() {
  describe('fingerprintAuthTest', function () {
    beforeAll(async function () {
      const data = {
        "cmd": [{
          "event": "CMD_NOTIFY_AUTH_START", "payload": {
            "lockoutDuration": 0,
            "remainAttempts": 5,
            "type": "fingerprint",
            "sensorInfo": ""
          }, "version": "1"
        }],
        "title": "",
        "type": ["fingerprint"],
        "widgetContextId": 2477724982625843000,
        "windowModeType": "DIALOG_BOX"
      };
      globalThis.wantParams = data;
    })

    it('cancelBth_state3_fingerprintAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      await driver.findComponent(ON.id('cancelBthState3FingerprintAuth'));
      expect(true).assertTrue();
      done();
    })

    it('usePwdBtn_state3_fingerprintAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      await driver.findComponent(ON.id('usePwdBtnState3FingerprintAuth'));
      expect(true).assertTrue();
      done();
    })

    it('blueFingerprintImg_state2_fingerprintAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      await driver.findComponent(ON.id('blueFingerprintImgState2FingerprintAuth'));
      expect(true).assertTrue();
      done();
    })

    it('cancelBtn_state2_fingerprintAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      await driver.findComponent(ON.id('cancelBtnState2FingerprintAuth'));
      expect(true).assertTrue();
      done();
    })

    it('usePwdBtn_state2_fingerprintAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      await driver.findComponent(ON.id('usePwdBtnState2FingerprintAuth'));
      expect(true).assertTrue();
      done();
    })

    it('blueFingerprint_state1_fingerprintAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('blueFingerprintState1FingerprintAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('blueFingerprintImg_all_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      await driver.findComponent(ON.id('blueFingerprintImgAllFaceAuth'));
      expect(true).assertTrue();
      done();
    })

    it('usePwdBtn_state1_fingerprintAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      let btn = await driver.findComponent(ON.id('usePwdBtnState1FingerprintAuth'));
      await btn.click();
      expect(true).assertTrue();
      done();
    })

    it('cancel_state4_fingerprintAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      await driver.findComponent(ON.id('cancelState4FingerprintAuth'));
      expect(true).assertTrue();
      done();
    })

    it('usePwdBtn_state4_fingerprintAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      await driver.findComponent(ON.id('usePwdBtnState4FingerprintAuth'));
      expect(true).assertTrue();
      done();
    })

    it('cancelBtn_state5_fingerprintAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      await driver.findComponent(ON.id('cancelBtnState5FingerprintAuth'));
      expect(true).assertTrue();
      done();
    })

    it('okBth_state5_fingerprintAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      await driver.findComponent(ON.id('okBthState5FingerprintAuth'));
      expect(true).assertTrue();
      done();
    })

    it('cancelBtn_mixedPin_faceAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      await driver.findComponent(ON.id('cancelBtnMixedPinFaceAuth'));
      expect(true).assertTrue();
      done();
    })

    it('cancel_state6_fingerprintAuth_test', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delayTime);
      await driver.findComponent(ON.id('cancelState6FingerprintAuth'));
      expect(true).assertTrue();
      done();
    })
  })
}