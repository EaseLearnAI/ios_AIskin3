# 支付宝 iOS SDK 来源与接入

本目录使用支付宝官方 CocoaPods 发布包的原始二进制，未使用第三方 Swift 包装，也未修改 framework 内文件。

- 版本：`AlipaySDK-iOS 15.8.30`。这是 2026-09-11 查询官方推荐包的 CocoaPods registry 返回的最高版本；不据此宣称其他发布渠道没有更新版本。
- 官方接入指南：[App 支付产品接入指南](https://aipay.alipay.com/docs/vibe-pay/mobile-app-pay/app-pay-integration-guide-new.html)。该指南明确推荐 `AlipaySDK-iOS`。
- 发布清单：[CocoaPods podspec](https://trunk.cocoapods.org/api/v1/pods/AlipaySDK-iOS/specs/15.8.30)，本地保留为 `AlipaySDK-iOS.podspec.json`。
- 原始下载：[支付宝 CDN ZIP](https://mdn.alipayobjects.com/mobilecashier_res/afts/file/lEoLQ64WOGAAAAAAAAAAAAAADnW6AQBr)。
- ZIP SHA-256：`9391ce3555c86321d19a67eaf6b8a04702582476a90e19e3b75e141a33d98e70`。
- 许可：随包的 `LICENSE`，MIT / Antfin。去掉 ZIP 的 `__MACOSX` 元数据，保留业务 SDK、资源及许可。
- 文件哈希在 `artifact-manifest.json` 中，可核对后续文件变动。

## 工程配置

`AlipaySDK.xcframework` 是静态 SDK，加入目标的 Link Binary With Libraries，不进行 Embed & Sign；把外层 `AlipaySDK.bundle` 加入资源。按 podspec 链接 UIKit、Foundation、CFNetwork、SystemConfiguration、QuartzCore、CoreGraphics、CoreMotion、CoreTelephony、CoreText、WebKit，以及 `c++`、`z`。

实际 xcframework 的 Info.plist 和 Mach-O 均含 `ios-arm64`、`ios-arm64_x86_64-simulator`。无需沿用 podspec 中排除模拟器 arm64 的旧设置。模拟器可以编译和验证 App 状态流转，但桥接拒绝在模拟器发起付款。

应用 Info.plist 注册 `CFBundleURLTypes → CFBundleURLSchemes → aiskin-alipay`，并添加查询 scheme `alipay`、`alipays`。`AISkinAlipayEnabled` 缺省为 false，由发布渠道明确配置；当前项目 Debug 开启、Release 关闭，不能因此默认认为 App Store 分发已获准使用外部支付。

桥接在 `AIskin/Core/Payments`，由应用注入一个 `AlipayPaymentLauncher` 实例。SwiftUI `.onOpenURL` 调用 `handleOpenURL`，返回 true 后从服务器恢复待处理订单；回到前台也应查单，覆盖钱包未回调或 App 被系统终止的情况。

## 支付信任边界

只将服务端返回的原始 `orderString` 传给 `launch(orderString:environment:)`。客户端不保存私钥、不签名、不重新拼接金额、不记录完整支付串或回跳 URL。

`PaymentSDKSignal` 是钱包操作信号，不是支付成功凭证。包括 `9000` 在内的任何 SDK 状态、URL 回跳、取消和超时，都只触发服务端订单查询；会员权益必须来自服务端验证后的会员状态。桥接保证一次调用的 continuation 只恢复一次，持有旧调用 ID 的 SDK 回调不会完成新的调用。URL 内容本身不作为订单归属证明。

标准支付宝 iOS APP 支付不提供沙箱钱包，也不支持 iOS APP 支付的沙箱测试；参见[支付宝官方说明](https://global.alipay.com/developer/helpcenter/detail?_route=sg&categoryId=50477&knowId=201602452726&sceneCode=AC_DEV)。桥接直接拒绝 `sandbox` 和未知环境，不将沙箱签名传给正式钱包。Android 沙箱的支付验收与 iPhone 正式环境的验收必须分开记录。

## 本轮验证及未完成项

- 对照下载包的真实 `AlipaySDK.h` 实现 `payOrder:fromScheme:callback:` 与 `processOrderWithPaymentResult:standbyCallback:`。
- 桥接使用项目的 Swift 5 / MainActor 默认隔离，分别通过真机 arm64 和模拟器 arm64 的 Swift 类型检查。
- 最新官方指南提到可选的 `registerApp:universalLink:`，但此版本头文件中没有该接口；桥接不调用不存在的方法。当前使用 URL Scheme 回跳。
- 这些结果不代表已发生付款，也不代表已收到支付宝真实回调。还须按主任务记录完成整个 App 构建、订单恢复测试，以及具备正式支付资质后的真机付款验证。
- 该官方归档未附带 `PrivacyInfo.xcprivacy`。正式发布前应依据官方 SDK 隐私说明和实际使用数据核对披露要求；本目录没有伪造供应商隐私声明。
