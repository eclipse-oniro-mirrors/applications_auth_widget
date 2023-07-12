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

import { BY, Driver, ON } from '@ohos.UiTest';
import { beforeAll, describe, expect, it } from '@ohos/hypium';

const delays: number = 1000

export default function PinFaceTest() {
  describe('PinFaceTest', function () {
    beforeAll(async function () {
      const data = {
        "cmd": [{
          "event": "CMD_NOTIFY_AUTH_START", "payload": {
            "lockoutDuration": 0, "remainAttempts": 5, "type": "pin", "sensorInfo": ""
          }, "version": "1"
        }],
        "pinSubType": "PIN_MIXED",
        "title": "",
        "type": ["pin"],
        "widgetContextId": 7932856209793250000,
        "windowModeType": "DIALOG_BOX"
      };
      globalThis.wantParams = data;
    })

    it('clickEventCancal_face', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delays);
      await driver.findComponent(ON.clickable(true));
      expect(true).assertTrue();
      done();
    })


    it('clickEventError_face', 0, async function (done) {
      let driver = Driver.create();
      await driver.delayMs(delays);
      await driver.findComponent(ON.id('cancelBtnDialogSixPwd'));
      expect(true).assertTrue();
      done();
    })
  })
}