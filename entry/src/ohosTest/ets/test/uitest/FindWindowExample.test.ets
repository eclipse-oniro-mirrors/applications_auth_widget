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

import { describe, expect, it, TestType } from '@ohos/hypium';
import { Driver } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import Want from '@ohos.app.ability.Want';

const delegator = abilityDelegatorRegistry.getAbilityDelegator();
const bundleName = abilityDelegatorRegistry.getArguments().bundleName;

const delays = 1000;

export default function FindWindowExampleTest() {
  describe('FindWindowExampleTest', () => {
    it('findWindowExampleTest_bundleName', TestType.FUNCTION, async (done: Function) => {
      let want: Want = {
        bundleName: bundleName,
        abilityName: "TestAbility"
      }
      await delegator.startAbility(want);
      let driver = Driver.create();
      await driver.delayMs(delays);
      await driver.findWindow({
        bundleName: bundleName
      });
      expect(true).assertTrue();
      done();
    })
  })
}