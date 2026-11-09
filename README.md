 迷雾档案 · 校园线索推理与多结局探索 App

玩家扮演调查员，在校园里走访三个场景，翻找线索、分清哪些是干扰项，攒够之后进入推理；最后看手里的证据和作出的选择，会走到三种不同结局。中途退出再打开，之前的进度能恢复，也可以一键清空、重新立案。

一、功能清单

委托页：先看主题和档案介绍，点"接受委托"就进入场景选择。
场景选择：入口有图书馆自习室、教学楼走廊、食堂门口三个；已经走访过的场景会打标记。
场景调查：每个场景有5个可点击的位置，其中2个翻不出东西。点到有效位置会弹出浮层，倒计时5秒后这条线索自动进线索板；已经调查过的位置会置灰，不能再点。
线索板：按收集顺序列出线索，关键线索会单独标注，条数实时显示。
推理门槛：有效线索不够6条时进不了推理，按钮置灰并提示线索不足。
多结局：一共三种结局——证据链闭合且指认同学是真相大白；指认校外人员是误判；证据不够就封存案件。
存档恢复：当前页面、线索、调查记录和结局都存在Preferences里，杀进程重进会自动恢复；存档文件损坏时退回全新状态，不会报错卡住。
重开新案：清空线索、调查记录、结局和本地存档，回到委托页。
自动化测试：10条Hypium用例，分别覆盖正常、边界、异常三种情况。

二、开发环境
IDE：DevEco Studio
工程模型：Stage 模型，ArkTS + ArkUI 声明式开发
存储：Preferences（`@ohos.data.preferences`）
测试框架：Hypium（`@ohos/hypium`）
运行目标：HarmonyOS 手机模拟器或真机

三、目录结构


四、运行方法

1. 打开DevEco Studio，新建一个Empty Stage工程，模块名entry，语言选ArkTS，UI模式选ArkUI。
2. 对照上面的目录结构，把仓库里entry/src/main/ets/和entry/src/main/resources/base/profile/main_pages.json拷到新工程对应位置，同名文件直接覆盖。
3. 看一下entry/src/main/module.json5里有没有注册入口Ability，关键片段如下：
```json5
"abilities": [
  {
    "name": "EntryAbility",
    "srcEntry": "./ets/entryability/EntryAbility.ets",
    "description": "$string:EntryAbility_desc",
    "icon": "$media:icon",
    "label": "$string:EntryAbility_label",
    "startWindowIcon": "$media:icon",
    "startWindowBackground": "$color:start_window_background",
    "exported": true,
    "skills": [
      {
        "entities": ["entity.system.home"],
        "actions": ["action.system.home"]
      }
    ]
  }
]
```
4. 启动手机模拟器，或者连上真机，点Run运行。

五、测试方法

在DevEco Studio右侧Test Explorer/运行测试里选中entry/src/ohosTest/ets/test/List.test.ets，右键Run。
也可以在工程根目录走命令行：
```bash
hvigorw ohosTest
```
10条用例分别是：线索入库、无用线索过滤、重复调查去重、6条门槛边界、真相结局判定、误判/封存判定、重开清空、序列化恢复、损坏JSON回退、倒计时中途退出后补录线索。

六、运行截图

委托页、场景选择、三个调查场景、线索板、推理选项、三种结局，还有存档恢复前后的对比，这些实跑截图都收在期末大作业报告附录里。想在仓库里再归档一份的话，可以放进screenshots/目录并在这里挂上链接。

七、录屏要求

需要录一段把流程完整走一遍的视频：接受委托→走访三个场景，点到有效和无效位置→看线索板→凑满6条进推理→选判断、看到结局→杀进程重进，确认进度恢复→重开新案清空。录屏文件放到docs/record/，再在仓库里链接出来。
