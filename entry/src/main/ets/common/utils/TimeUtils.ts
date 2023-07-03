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
export class TimeUtils {
  getFreezingTimeNm(freezingMillisecond: number): string {
    const MINUTE_NM = '分钟';
    const SECOND_NM = '秒';
    let minute = Math.floor(freezingMillisecond / (60 * 1000));
    let second = Math.round((freezingMillisecond % (60 * 1000)) / 1000);
    let timeName = '';
    if (minute != 0) {
      timeName += minute + MINUTE_NM;
    }
    if (second != 0) {
      timeName += second + SECOND_NM;
    }
    return timeName;
  }
}

let mTimeUtils = new TimeUtils();

export default mTimeUtils as TimeUtils;
