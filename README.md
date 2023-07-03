# 统一认证控件

- [简介](#简介)
- [目录](#目录)
- [说明](#说明)
  - [使用说明](#使用说明)
- [相关仓](#相关仓)
## 简介

**统一认证控件** 配套统一用户认证框架（user_auth_framework），提供统一的用户身份认证控件能力，在统一用户认证框架处理用户认证请求时，提供用户认证交互界面，支持用户通过界面操作选项切换认证方式或取消认证，支持业务自定义控件显示信息。
**图1** 统一认证控件架构图
<img src="figures/统一认证控件架构图.png" alt="统一认证控件架构图" style="zoom:80%;" />

## 目录

```
//base/useriam/auth_widget
├── entry                              # entry模块目录
│   ├── src/main
│   │          ├─ets
│   │          │  └─extensionability   # 系统弹框扩展能力实现，入口
│   │          │  └─common             # 公共工具目录
│   │          │  └─pages              # 弹框内容页面
│   │          │  └─image              # 页面使用的预置图标资源
│   │          └─resources             # 资源文件
│   │          └─module.json5          # 全局配置文件
│   └─ src/ohostest                    # arkXTest实现的自动化单元测试
├── signature                          # 证书文件目录
├── LICENSE                            # 许可文件
└── figures                            # readme的截图
```

## 说明

### 使用说明

1.  统一认证控件是采用系统弹框能力实现的UIExtensionAbility,对应组件UIExtensionComponent的类型ExtensionType:sysDialog/userAuth；是非常驻系统预置应用，只能由统一认证框架服务拉起、管理，不对外开放接口。
2.  调用者使用统一认证控件，仅需参考统一认证框架北向使用指导，选择使用带控件的接口getUserAuthInstance,AuthParam指定认证参数，WidgetParam指定控件显示参数。

## 相关仓

**[useriam_user_auth_framework](https://gitee.com/openharmony/useriam_user_auth_framework)**