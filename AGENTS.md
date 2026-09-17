# 统一认证控件（auth_widget）工程指引

## 项目定位

本仓库对应 OpenHarmony `applications/standard/auth_widget`，是统一用户认证框架（user_auth_framework）配套的**系统弹框扩展能力**应用。当 `user_auth_framework` 处理用户认证请求时，由本应用提供 PIN/人脸/指纹的认证交互界面，并支持业务应用自定义标题、导航按钮，允许用户切换认证方式或取消认证。

- 组件名：`auth_widget`，subsystem：`applications`（见 `bundle.json`）
- 入口扩展能力：`userauthuiextensionability`，类型 `sysDialog/userAuth`，srcEntry 为 `entry/src/main/ets/extensionability/UserAuthAbility.ts`
- 主页面：`entry/src/main/ets/pages/Index.ets`，按 `windowModeType`（`DIALOG_BOX`/全屏）与 `authType` 分发到各认证组件

优先按这些目录定位问题：

- `entry/src/main/ets/extensionability/`：扩展能力生命周期、会话管理、窗口背景与隐私模式
- `entry/src/main/ets/pages/`：认证类型分发、横竖屏与屏下指纹判断
- `entry/src/main/ets/common/utils/`：`AuthUtils`（sendNotice 通知）、`FuncUtils`、`LogUtils`、`TimeUtils`
- `entry/src/main/ets/common/vm/`：常量、`WantParams`/`WidgetCommand`/`CmdType`/`TipCode` 接口
- `entry/src/main/ets/common/module/`：弹框类型枚举 `DialogType`
- `entry/src/main/ets/common/components/`：可复用控件（`PassWord`、`SixPassword`、`NumkeyBoard`、`FullScreen`）
- `entry/src/main/resources/`：字符串、颜色、浮点数、图标等资源文件
- `entry/src/ohostest/`：单元测试（jsunit）、UI 自动化测试（uitest）

### 按任务类型定位代码

| 任务类型 | 首选目录 | 关键文件 |
| --- | --- | --- |
| 扩展能力生命周期、会话创建/销毁、窗口背景与隐私模式 | `entry/src/main/ets/extensionability/` | `UserAuthAbility.ts` |
| 认证类型分发、横竖屏与屏下指纹判断 | `entry/src/main/ets/pages/` | `Index.ets` |
| PIN 认证（弹框模式）、PIN 过期/冻结/剩余次数提示 | `entry/src/main/ets/pages/components/` | `PasswordAuth.ets` |
| 人脸认证 UI、人脸/指纹/PIN 组合布局、传感器位置 | `entry/src/main/ets/pages/components/` | `FaceAuth.ets` |
| 指纹认证 UI、不同指纹传感器适配 | `entry/src/main/ets/pages/components/` | `FingerprintAuth.ets` |
| 全屏 PIN（自定义密码）场景 | `entry/src/main/ets/pages/components/` | `CustomPassword.ets` |
| PIN 输入框、六位密码、数字键盘、全屏容器等可复用控件 | `entry/src/main/ets/common/components/` | `PassWord.ets`、`SixPassword.ets`、`NumkeyBoard.ets`、`FullScreen.ets` |
| 向 user_auth_framework 发送通知（sendNotice） | `entry/src/main/ets/common/utils/` | `AuthUtils.ts` |
| 通用函数（TextEncoder、DialogType 推导、窗口高度、资源字符串） | `entry/src/main/ets/common/utils/` | `FuncUtils.ts` |
| 日志（hiLog，DOMAIN 0x0007，TAG `useriam_auth_widget`） | `entry/src/main/ets/common/utils/` | `LogUtils.ts` |
| 冻结时间本地化文案 | `entry/src/main/ets/common/utils/` | `TimeUtils.ts` |
| 窗口隐私模式设置 | `entry/src/main/ets/common/utils/` | `WindowPrivacyUtils.ts` |
| 常量、`WantParams`/`WidgetCommand`/`CmdType` 等接口、`TipCode` 枚举 | `entry/src/main/ets/common/vm/` | `Constants.ts` |
| 弹框类型枚举 | `entry/src/main/ets/common/module/` | `DialogType.ts` |
| 模块声明、扩展能力注册、权限申请 | `entry/src/main/` | `module.json5` |
| 资源（string/float/color/media/profile） | `entry/src/main/resources/{base,zh_CN,en_US}/` | `element/string.json`、`element/float.json`、`profile/main_pages.json` |
| 单元/UI 自动化测试（arkXTest + hypium） | `entry/src/ohostest/ets/test/` | `List.test.ets`、`jsunit/`、`uitest/` |

### 嵌套指引

本仓库无目录级别的嵌套指引。所有任务级指导已在本文档"知识索引"章节提供，无需额外阅读文档。

## 构建和验证

构建命令从 OpenHarmony 源码根目录执行，不在本子目录执行。

```sh
./build.sh --product-name rk3568 --ccache --build-target auth_widget
```

运行单元测试：

```sh
# arkTS 测试（在 ohosTest 目录下）
# 使用 @ohos/hypium 测试框架
```

### 测试任务分发

根据改动类型选择对应测试：

| 改动类型 | 测试目标 | 验证方式 |
| --- | --- | --- |
| UI 布局、样式、组件渲染 | `entry/src/ohostest/ets/uitest/` | 端到端 UI 测试，板侧执行 |
| 协议结构、`sendNotice` 事件、`WantParams`/`WidgetCommand` | `entry/src/ohostest/ets/test/` | jsunit 单元测试，验证数据结构和事件发送 |
| PIN 输入流程、锁定/冻结逻辑、`registerInputer` | `PasswordAuth.ets` 相关测试 | 结合 `hdc shell` 日志验证 PIN 回调链路 |
| 跨组件协作（Index 与 FaceAuth/FingerprintAuth/PasswordAuth） | 完整认证流程 | 板侧端到端测试，触发真实 user_auth_framework 调用 |
| 资源文件变更（字符串、颜色、尺寸） | 多语言一致性 | 检查 `zh_CN/element/string.json` 与 `en_US/element/string.json` 是否同步 |
| ArkTS 代码规范（类型注解、接口签名） | ESLint + ArkTS compiler | `hvigor check` 或 IDE 内置检查 |
| 隐私模式、权限声明 | 代码审查 | 检查 `module.json5` 权限列表和 `setWindowPrivacyMode` 调用 |

### 完成标准

任务被认为完成，当且仅当：

1. **代码改动已提交** - 使用 `git commit -s`，多代理协作时添加 `Co-Authored-By: Agent`
2. **本地构建通过** - 执行上述构建命令，`auth_widget` 目标构建成功，且无 ESLint/ArkTS 类型错误
3. **相关测试通过** - 对应 `entry/src/ohostest` 下的 jsunit/uitest 用例在板侧通过
4. **协议兼容性验证** - `sendNotice` 事件结构、字段顺序、类型与 `Constants.ts` 定义一致
5. **板侧验证（如适用）** - 涉及 UI 布局、横竖屏、屏下指纹、冻结/锁定流程、权限弹窗的改动需提供截图或录屏证据
6. **文档/资源更新（如适用）** - 新增/修改用户可见文案必须同步 `zh_CN/element/string.json` 与 `en_US/element/string.json`；公共能力变更需更新 README

### 如果无法运行验证

明确说明无法运行的原因，列出推荐的验证步骤供人工执行，标记需要人工验证的部分。

### 完成报告格式

报告应包含：改动摘要（文件列表、改动点）、验证结果（构建/测试输出）、风险评估（API 兼容性、权限、性能风险）、未完成事项。

## 知识索引

改动前按场景读取对应文件：

### 场景与路径路由

| 场景 | 修改目录 | 先读文档 |
| --- | --- | --- |
| 扩展能力生命周期、`UIExtensionContentSession` 加载内容、窗口背景/隐私模式、`AppStorage` 全局状态键 | `entry/src/main/ets/extensionability/` | `UserAuthAbility.ts` |
| `WantParams`/`WidgetCommand` 协议、`sendNotice` 事件、`CmdType`/`TipCode`、与 `user_auth_framework` 的命令/通知契约 | `entry/src/main/ets/common/utils/AuthUtils.ts`、`common/vm/Constants.ts` | `Constants.ts` WantParams/WidgetCommand 章节 |
| PIN/人脸/指纹组合分发的 `DialogType` 推导、`windowModeType` 分支、认证组件路由 | `entry/src/main/ets/pages/Index.ets`、`common/module/DialogType.ts` | `Index.ets` 路由分发章节 |
| 横竖屏与屏下指纹（`UNDER_SCREEN_SENSOR`/`BOTH_SENSOR`/`SensorType1`）适配、横屏仅 PIN 时 5s 自动关闭 | `entry/src/main/ets/pages/Index.ets`、`pages/components/FaceAuth.ets`、`pages/components/FingerprintAuth.ets` | `FingerprintAuth.ets` 传感器适配章节 |
| PIN 过期/冻结/剩余次数提示、`PINAuth.registerInputer`/`unregisterInputer`、密码清除 | `entry/src/main/ets/pages/components/PasswordAuth.ets`、`pages/components/CustomPassword.ets` | `PasswordAuth.ets` 锁定流程章节 |
| 预置资源、多语言文案、尺寸/颜色/图标、`main_pages` 路由 | `entry/src/main/resources/` | `element/string.json`、`element/float.json` |
| 构建、板侧测试、HAP 安装、触发认证控件的端到端验证 | 任何构建/测试相关改动 | 参考本文档"构建和验证"章节 |

### 术语与知识入口

遇到以下领域术语时，优先阅读对应文件：

| 领域术语 | 优先阅读 | 原因 |
| --- | --- | --- |
| `WantParams`、`widgetContextId`、`sendNotice` | `AuthUtils.ts`、`Constants.ts` | 协议契约核心，跨进程数据结构定义 |
| `WidgetCommand`、`CmdType`、`onCmdDataChange` | `Index.ets` 第 1-80 行、`Constants.ts` | 命令处理入口，WidgetCommand 在 Index.ets 解析分发 |
| `DialogType`、`PIN_FACE`、`PIN_FINGER`、`ALL` | `DialogType.ts`、`Index.ets` | 认证类型组合推导逻辑 |
| `TipCode`、`lockoutDuration`、`remainAttempts` | `Constants.ts` | 提示码和锁定状态定义 |
| `FingerPosition`、`UNDER_SCREEN_SENSOR`、`BOTH_SENSOR` | `FingerprintAuth.ets` | 屏下指纹传感器适配逻辑 |
| `windowModeType`、`DIALOG_BOX` | `UserAuthAbility.ts`、`Index.ets` | 窗口模式决定页面路由 |
| `privacyMode`、`setWindowPrivacyMode` | `WindowPrivacyUtils.ts` | 隐私模式窗口设置 |
| `AppStorage` 全局键（`wantParams`、`session`、`IS_LANDSCAPE`） | `UserAuthAbility.ts` 第 30-60 行 | 全局状态初始化和管理 |
| `pinSubType`、`PIN_SIX`、`PIN_NUMBER`、`PIN_MIXED` | `PasswordAuth.ets` | PIN 格式和输入框类型 |
| `EVENT_AUTH_*`（noticeEvent* 事件名字符串） | `Constants.ts`、`AuthUtils.ts` | 事件名称常量定义和使用位置 |

### 开始编辑前

在修改代码前，按以下顺序确认：
1. 确认任务类别（UI 布局 / 协议契约 / 生命周期 / 资源 / 测试）
2. 根据上表确定需要阅读的文档（若尚未存在，先在本表登记路径再据需要创建）
3. 根据"项目约束"确认不违反任何约束
4. 声明："我将修改 X，已阅读 Y 文档，遵循 Z 约束"

## 项目约束

### 性能约束

- 认证控件是系统弹框，用户可感知；避免在 `build()`、`onCmdDataChange`、`onTextValueChange` 等高频回调中做全量 `JSON.stringify`/正则替换或打印 INFO 日志
- `AppStorage` 读写频繁的键（`wantParams`、`session`、`IS_LANDSCAPE`、`SYSTEM_*_BAR_HEIGHT`、`titleLength`、`widgetContextId`）保持轻量，勿存放大对象
- `sendNotice` 为跨进程 IPC，不得在密码每次按键时调用，仅在状态变更（加载完成/取消/导航/释放/终止）时触发

### 架构约束

- `UserAuthAbility` 仅负责会话与窗口，不承载业务逻辑；业务分发集中在 `Index.ets`，认证 UI 在 `pages/components/`，可复用控件在 `common/components/`，工具在 `common/utils/`，常量/类型在 `common/vm/`
- `DialogType` 的组合归属规则（PIN/FACE/FINGER 的组合枚举）要保持显式，不要在 UI 中用魔法数字代替 `DialogType` 枚举或 `Constants.ts` 常量
- `AuthUtils` 为单例（`getInstance()`），`widgetContextId` 在构造时从 `AppStorage` 读取一次；不要在每次 `sendNotice` 重复解析或新增多实例
- 窗口背景色（`TRANSPARENT_COLOR`/`MASK_THIN_COLOR`）与 `windowModeType` 的对应关系不要打破：`DIALOG_BOX` 用半透明遮罩，其余用透明

### 编码约定

- ArkTS 改动优先复用附近的工具：日志用 `LogUtils`（`debug/info/warn/error/fatal`），资源字符串用 `FuncUtils.getResourceString`，时间格式化用 `TimeUtils`
- 跨进程会话对象（`UIExtensionContentSession`）调用需 try/catch，错误用 `error?.code` 记录并 `terminateSelf()` 兜底，沿用现有模式
- 对 `AppStorage.get('session')`/`wantParams` 等可空对象做判空，模式与 `UserAuthAbility.ts` 一致（`as UIExtensionContentSession`/`as WantParams` 后再使用）
- 新增事件字符串、`CmdNotifyEvents`/`TipCode` 枚举值前，先与 `user_auth_framework` 侧对齐，避免字符串硬编码散落

### 常见 Agent 失误模式

**必须避免的失误：**
- 用 `as` 做类型转换时不判空（正确模式：`const session = AppStorage.get('session') as UIExtensionContentSession; if (!session) return;`）
- 在 `build()` 或 `onCmdDataChange` 中做 JSON.stringify 正则替换或打印非必要的日志
- 在 `sendNotice` 的每次按键事件中调用 IPC（应仅在状态变更时调用）
- 在 `registerInputer.onGetData` 之外输出或传输 PIN 数据
- 创建多个 `AuthUtils` 实例（应使用 `AuthUtils.getInstance()` 单例）
- 在屏下指纹场景不使用 `FingerPosition` 而用魔法数字判断传感器类型

### 公共 API 约束

本工程不对外暴露 Native/NAPI/IDL 接口，但以下对外契约须保持稳定：

**Do not（禁止）：**
- 修改 `UserAuthAbility` 的扩展能力类型 `sysDialog/userAuth`、`mainElement`、`srcEntry` 路径约定
- 修改 `module.json5` 中已声明的 `requestPermissions` 列表移除项（`ACCESS_PIN_AUTH`/`ACCESS_BIOMETRIC`/`SUPPORT_USER_AUTH`/`PRIVACY_WINDOW`）
- 修改 `sendNotice` 的 `eventData` 结构（`widgetContextId`/`event`/`version`/`payload{type,tipCode}`）字段顺序或类型
- 修改 `WantParams`/`WidgetCommand`/`CmdType`/`CmdData` 等跨进程数据结构字段名与类型

**Ask before（修改前必须确认）：**
- 新增 `sendNotice` 事件：确认 `user_auth_framework` 是否已识别该事件名
- 修改 `widgetContextId` 解析方式（`BigInt(AppStorage.get<string>('widgetContextId'))`）：确认对端传递的字符串格式
- 修改 `UserAuthWidgetMgr.on('command', ...)` 的回调字段使用：确认 `userAuth` SDK 版本兼容性

### 安全与权限边界

**Do not（禁止）：**
- 绕过 `module.json5` 中的权限声明或在运行时跳过 `setWindowPrivacyMode` 调用
- 将用户输入的 PIN 明文（`pinData`/`textValue`）写入非调试日志或全局可读存储
- 在 `registerInputer.onGetData` 之外的地方输出或传输 PIN（应仅通过 `callback.onSetData` 回传 `Uint8Array`）
- 关闭窗口隐私模式或删除 `PRIVACY_WINDOW` 权限，PIN 输入必须始终处于隐私模式

**Ask before（修改前必须确认）：**
- 涉及 `ohos.permission.ACCESS_PIN_AUTH`/`ACCESS_BIOMETRIC`/`SUPPORT_USER_AUTH`/`PRIVACY_WINDOW` 的改动
- 涉及 `setWindowPrivacyMode`、窗口背景透明度等可能被截屏/录屏利用的改动
- 涉及生物识别（人脸/指纹）结果、剩余尝试次数、锁定时长的展示逻辑（属隐私信息）
- 任何把 `wantParams`（含 `widgetContextId`、标题等业务方数据）写入持久化日志的改动

### 协议与数据格式兼容性

**Do not（禁止）：**
- 修改 `sendNotice` payload 的 JSON 结构与字段顺序
- 修改 `WidgetCommand` 的字段（`cmd`/`pinSubType`/`skipLockedBiometricAuth`）及 `CmdType`（`event`/`payload`）
- 修改 `FingerPosition.sensorType` 的取值常量（`UNDER_SCREEN_SENSOR`/`BOTH_SENSOR`/`SensorType1`）
- 修改 `noticeTypePin`/`noticeTypeFace`/`noticeTypeFinger` 及 `noticeEvent*` 事件名字符串

**Ask before（修改前必须确认）：**
- 新增 `CmdNotifyEvents` 枚举或 `UserAuthTipType`：确认对端会发送/接收
- 修改 `pinSubType` 取值（`PIN_SIX`/`PIN_NUMBER`/`PIN_MIXED`）：确认 PIN 框架侧兼容
- 修改 `noticeVersion`：确认协议版本协商策略

### 生成代码边界

本工程无 IDL 生成代码。涉及 SDK 调用的边界：

**Do not（禁止）：**
- 修改 `@ohos.userIAM.userAuth`、`@ohos.account.osAccount`、`@ohos.app.ability.UserAuthExtensionAbility` 等 SDK 的类型声明或 shim
- 用 `any` 绕过 `IInputData`/`UIExtensionContentSession` 等接口签名

**正确做法：**
- 通过 `import type` 引入类型，运行时调用走官方 SDK
- 对 SDK 行为不确定时，以 `user_auth_framework` 与 `@ohos.userIAM.userAuth` 的公共文档为准

### 设备操作约束

**涉及真实设备时的注意事项：**
- 不执行可能影响设备正常运行的破坏性操作；本应用仅展示 UI，不直接操作生物识别硬件
- 涉及真实设备的改动（横竖屏、屏下指纹、人脸/指纹结果展示）必须提供板侧证据（截图/录屏/hdc 日志）
- 触发认证控件需真实用户身份（PIN/指纹/人脸）已录入，且 `user_auth_framework` 服务可用；不得通过伪造 `wantParams` 绕过对端校验
- 窗口隐私模式涉及安全录像防护，验证时如需截屏须明确说明用途并经安全评审

## 关键依赖与外部协同

- **上游**：`user_auth_framework`（统一用户认证框架）。本应用通过 `userAuth.getUserAuthWidgetMgr(version).on('command', ...)` 接收 `WidgetCommand`，通过 `userAuth.sendNotice(WIDGET_NOTICE, json)` 回送事件。任何协议改动须与上游对齐
- **SDK 依赖**：`@ohos.userIAM.userAuth`、`@ohos.account.osAccount`（`PINAuth`/`registerInputer`/`AuthSubType`）、`@ohos.app.ability.UserAuthExtensionAbility`/`UIExtensionContentSession`、`@ohos.screen`、`@ohos.display`、`@ohos.window`、`@ohos.hilog`、`@ohos.util`
- **权限**：`ACCESS_PIN_AUTH`、`ACCESS_BIOMETRIC`、`SUPPORT_USER_AUTH`、`PRIVACY_WINDOW`
- **测试框架**：`@ohos/hypium`（jsunit 单测）、arkXTest（uitest 端到端，需配合 `testability/*Ability.ets` 驱动）
