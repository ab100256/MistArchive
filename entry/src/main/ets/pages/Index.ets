import { GameEngine } from '../model/GameEngine';
import { ArchiveStore } from '../store/ArchiveStore';
import {
  ALL_SCENES,
  SUSPECT_OPTIONS,
  MIN_CLUES_TO_REASON,
  CLUE_PRESENT_SECONDS,
  findClue,
  findScene,
  findEnding
} from '../model/GameData';
import {
  PageKey,
  SceneInfo,
  SceneSpot,
  Clue,
  EndingInfo,
  SuspectOption,
  InvestigateResult
} from '../model/Types';
import common from '@ohos.app.ability.common';

/** 配色常量 */
const COLOR_BG: string = '#F5F1E8';
const COLOR_INK: string = '#2B3A42';
const COLOR_LINE: string = '#2B3A42';
const COLOR_ACCENT: string = '#B4552D';
const COLOR_CARD: string = '#FFFFFF';
const COLOR_MUTED: string = '#8A9499';

/**
 * 迷雾档案 —— 主页面（页面状态机）
 * intro 接受委托 → sceneSelect 选择场景 → explore 场景调查
 * → clueBoard 线索板 → reasoning 案件推理 / 结局
 */
@Entry
@Component
struct Index {
  /** 纯逻辑引擎实例；引擎内部变更不直接驱动刷新，派生值统一拷贝到下面的 @State */
  private engine: GameEngine = new GameEngine();
  private store: ArchiveStore = new ArchiveStore();

  @State page: PageKey = 'intro';
  @State accepted: boolean = false;
  @State currentSceneId: string = '';
  @State collectedClueIds: string[] = [];
  @State visitedSpotIds: string[] = [];
  @State endingId: string = '';
  @State chosenSuspect: string = '';
  @State clueCount: number = 0;
  @State canReasonFlag: boolean = false;

  /** 线索浮层状态 */
  @State showClueCard: boolean = false;
  @State pendingClueId: string = '';
  @State countdown: number = CLUE_PRESENT_SECONDS;
  private clueTimer: number = -1;

  /** 页面内提示条 */
  @State showTip: boolean = false;
  @State tipText: string = '';
  private tipTimer: number = -1;

  aboutToAppear(): void {
    this.initArchive();
  }

  /** 初始化 Preferences 并恢复上次存档（异步，不阻塞首帧渲染） */
  private async initArchive(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    await this.store.init(context);
    const json: string = await this.store.loadSnapshot();
    if (json.length > 0) {
      this.engine = GameEngine.deserialize(json);
    }
    this.syncState();
  }

  aboutToDisappear(): void {
    this.clearClueTimer();
    this.clearTipTimer();
  }

  /** 把引擎最新状态拷贝到 @State，驱动 UI 刷新 */
  private syncState(): void {
    this.page = this.engine.page;
    this.accepted = this.engine.accepted;
    this.currentSceneId = this.engine.currentSceneId;
    this.collectedClueIds = this.engine.collectedClueIds.slice();
    this.visitedSpotIds = this.engine.visitedSpotIds.slice();
    this.endingId = this.engine.endingId;
    this.chosenSuspect = this.engine.chosenSuspect;
    this.clueCount = this.engine.clueCount;
    this.canReasonFlag = this.engine.canReason();
  }

  /** 持久化当前快照 */
  private async persist(): Promise<void> {
    await this.store.saveSnapshot(this.engine.serialize());
  }

  private clearClueTimer(): void {
    if (this.clueTimer >= 0) {
      clearInterval(this.clueTimer);
      this.clueTimer = -1;
    }
  }

  private clearTipTimer(): void {
    if (this.tipTimer >= 0) {
      clearInterval(this.tipTimer);
      this.tipTimer = -1;
    }
  }

  private pushTip(text: string): void {
    this.tipText = text;
    this.showTip = true;
    this.clearTipTimer();
    this.tipTimer = setInterval(() => {
      this.showTip = false;
      this.clearTipTimer();
    }, 2500);
  }

  // ==================== 业务动作 ====================

  /** 图1：接受委托 */
  private onAcceptCommission(): void {
    this.engine.acceptCommission();
    this.syncState();
    this.persist();
  }

  /** 图2：选择进入场景 */
  private onSelectScene(sceneId: string): void {
    this.engine.enterScene(sceneId);
    this.syncState();
    this.persist();
  }

  /** 图3：点击调查位置 */
  private onInvestigate(spot: SceneSpot): void {
    if (this.showClueCard) {
      this.pushTip('正在查看线索，请稍候');
      return;
    }
    const result: InvestigateResult = this.engine.investigate(spot.id);
    if (result.kind === 'visited') {
      this.pushTip('此处已经调查过');
      this.syncState();
      this.persist();
      return;
    }
    if (result.kind === 'useless') {
      this.pushTip('这里没有发现有用的线索');
      this.syncState();
      this.persist();
      return;
    }
    // 有效线索：弹出浮层，倒计时结束后自动入库
    this.pendingClueId = result.clueId;
    this.countdown = CLUE_PRESENT_SECONDS;
    this.showClueCard = true;
    this.clearClueTimer();
    this.clueTimer = setInterval(() => {
      this.countdown = this.countdown - 1;
      if (this.countdown <= 0) {
        this.finishPendingClue();
      }
    }, 1000);
    this.syncState();
    this.persist();
  }

  /** 倒计时结束：线索保存进线索板 */
  private finishPendingClue(): void {
    this.clearClueTimer();
    if (this.pendingClueId.length > 0) {
      this.engine.addClue(this.pendingClueId);
    }
    this.showClueCard = false;
    this.pendingClueId = '';
    this.syncState();
    this.persist();
    this.pushTip('线索已保存到线索板');
  }

  /** 离开场景页：若浮层未结束，先把线索入库，避免丢失 */
  private leaveScene(): void {
    if (this.showClueCard) {
      this.finishPendingClue();
    }
  }

  /** 图3 → 前往下一个场景（回图2） */
  private onNextScene(): void {
    this.leaveScene();
    this.engine.backToSceneSelect();
    this.syncState();
    this.persist();
  }

  /** 图3 → 案件推理（图4线索板） */
  private onGotoBoard(): void {
    this.leaveScene();
    this.engine.gotoClueBoard();
    this.syncState();
    this.persist();
  }

  /** 图4 → 继续寻找线索（回图2） */
  private onContinueSearch(): void {
    this.engine.backToSceneSelect();
    this.syncState();
    this.persist();
  }

  /** 图4 → 推理结果（图5）；线索不足时拦截 */
  private onGotoReasoning(): void {
    if (!this.canReasonFlag) {
      this.pushTip(`线索不足，至少收集 ${MIN_CLUES_TO_REASON} 条有效线索后再推理`);
      return;
    }
    this.engine.gotoReasoning();
    this.syncState();
    this.persist();
  }

  /** 图5：选择推理结论 */
  private onChooseSuspect(choiceId: string): void {
    this.engine.evaluateEnding(choiceId);
    this.syncState();
    this.persist();
  }

  /** 回到推理选项，重新选择结论（保留已收集线索） */
  private onRevokeEnding(): void {
    this.engine.revokeEnding();
    this.syncState();
    this.persist();
  }

  /** 重开新案：清空引擎状态与存档 */
  private async onRestart(): Promise<void> {
    this.clearClueTimer();
    this.showClueCard = false;
    this.pendingClueId = '';
    this.engine.reset();
    await this.store.clearSnapshot();
    this.syncState();
    this.pushTip('新案已开启，全部线索已清空');
  }

  // ==================== 派生取值 ====================

  private currentScene(): SceneInfo | null {
    return findScene(this.currentSceneId);
  }

  private sceneImage(): ResourceStr {
    const scene = this.currentScene();
    if (scene === null) {
      return $r('app.media.classroom');
    }
    if (scene.id === 'scene_lib') {
      return $r('app.media.scene_lib');
    }
    if (scene.id === 'scene_corridor') {
      return $r('app.media.scene_corridor');
    }
    return $r('app.media.scene_canteen');
  }

  private clueById(clueId: string): Clue | null {
    return findClue(clueId);
  }

  private isSpotVisited(spotId: string): boolean {
    return this.visitedSpotIds.indexOf(spotId) >= 0;
  }

  private sceneVisited(sceneId: string): boolean {
    const scene = findScene(sceneId);
    if (scene === null) {
      return false;
    }
    for (let i = 0; i < scene.spots.length; i++) {
      if (this.isSpotVisited(scene.spots[i].id)) {
        return true;
      }
    }
    return false;
  }

  private stageIndex(): number {
    if (this.endingId.length > 0) {
      return 3;
    }
    if (this.clueCount >= MIN_CLUES_TO_REASON) {
      return 2;
    }
    if (this.accepted) {
      return 1;
    }
    return 0;
  }

  private stageLabel(): string {
    const s: number = this.stageIndex();
    if (s === 3) {
      return '已结案';
    }
    if (s === 2) {
      return '可推理';
    }
    if (s === 1) {
      return '线索收集中';
    }
    return '待接受委托';
  }

  private stagePercent(): number {
    return Math.round(this.stageIndex() / 3 * 100);
  }

  private pendingClue(): Clue | null {
    return findClue(this.pendingClueId);
  }

  private currentEnding(): EndingInfo | null {
    return findEnding(this.endingId);
  }

  // ==================== UI ====================

  build() {
    Column() {
      this.Header();
      if (this.page === 'intro') {
        this.IntroPage();
      } else if (this.page === 'sceneSelect') {
        this.SceneSelectPage();
      } else if (this.page === 'explore') {
        this.ExplorePage();
      } else if (this.page === 'clueBoard') {
        this.ClueBoardPage();
      } else {
        this.ReasoningPage();
      }
      if (this.showTip) {
        this.TipBar();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BG)
  }

  /** 顶部：标题 + 阶段进度 + 线索计数 */
  @Builder Header() {
    Column() {
      Row() {
        Text('迷雾档案')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_INK)
        Blank()
        Text(`线索 ${this.clueCount}/${MIN_CLUES_TO_REASON}`)
          .fontSize(13)
          .fontColor(COLOR_ACCENT)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 14 })

      Row() {
        Stack() {
          Row()
            .width('100%')
            .height(8)
            .backgroundColor('#E2DCD0')
            .borderRadius(4)
          Row()
            .width(`${this.stagePercent()}%`)
            .height(8)
            .backgroundColor(COLOR_ACCENT)
            .borderRadius(4)
        }
        .layoutWeight(1)
        Text(this.stageLabel())
          .fontSize(12)
          .fontColor(COLOR_MUTED)
          .margin({ left: 10 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 8, bottom: 10 })
    }
    .width('100%')
    .backgroundColor(COLOR_BG)
  }

  /** 图1：委托页 */
  @Builder IntroPage() {
    Column() {
      // 主题框
      Column() {
        Text('迷雾档案')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_INK)
        Text('校园线索推理与多结局探索')
          .fontSize(14)
          .fontColor(COLOR_MUTED)
          .margin({ top: 8 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(COLOR_CARD)
      .border({ width: 3, color: COLOR_LINE })
      .padding(20)
      .margin({ left: 18, right: 18, top: 10 })

      // 档案介绍框
      Column() {
        Text('档案介绍')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_INK)
          .margin({ bottom: 10 })
        Text('晚自习结束后，302 实验室的一台平板不翼而飞，监控恰好缺失。你作为接受委托的调查员，需要走访图书馆自习室、教学楼走廊与食堂门口，收集足够的有效线索，在证据链闭合后作出最终判断。不同的线索组合，将把案件引向不同结局。')
          .fontSize(14)
          .fontColor(COLOR_INK)
          .lineHeight(22)
      }
      .width('100%')
      .layoutWeight(1.4)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(COLOR_CARD)
      .border({ width: 3, color: COLOR_LINE })
      .padding(18)
      .margin({ left: 18, right: 18, top: 14 })

      // 接受委托按钮
      Button('接受委托')
        .width('60%')
        .height(48)
        .backgroundColor(COLOR_ACCENT)
        .fontColor(Color.White)
        .fontSize(16)
        .margin({ top: 16, bottom: 18 })
        .onClick(() => {
          this.onAcceptCommission();
        })
    }
    .width('100%')
    .layoutWeight(1)
  }

  /** 图2：场景选择页 */
  @Builder SceneSelectPage() {
    Column() {
      // 教室背景图
      Image($r('app.media.classroom'))
        .width('100%')
        .layoutWeight(2)
        .objectFit(ImageFit.Cover)
        .border({ width: 3, color: COLOR_LINE })
        .margin({ left: 18, right: 18, top: 10 })
        .clip(true)

      // 三个场景按钮
      Row() {
        ForEach(ALL_SCENES, (scene: SceneInfo) => {
          Button() {
            Column() {
              Text(scene.name)
                .fontSize(13)
                .fontColor(Color.White)
                .textAlign(TextAlign.Center)
              if (this.sceneVisited(scene.id)) {
                Text('已走访')
                  .fontSize(10)
                  .fontColor('#FFE3D6')
                  .margin({ top: 4 })
              }
            }
          }
          .layoutWeight(1)
          .height(72)
          .backgroundColor(COLOR_INK)
          .margin({ left: 8, right: 8 })
          .onClick(() => {
            this.onSelectScene(scene.id);
          })
        }, (scene: SceneInfo) => scene.id)
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 18, bottom: 18 })
    }
    .width('100%')
    .layoutWeight(1)
  }

  /** 图3：场景调查页 */
  @Builder ExplorePage() {
    Stack() {
      Column() {
        // 场景说明
        Column() {
          Text(this.sceneNameText())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_INK)
          Text(this.sceneDescText())
            .fontSize(12)
            .fontColor(COLOR_MUTED)
            .lineHeight(18)
            .margin({ top: 6 })
          Text('本场景 5 个可调查位置，其中 2 个为无用线索')
            .fontSize(11)
            .fontColor(COLOR_ACCENT)
            .margin({ top: 6 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 20, right: 20, top: 10 })

        // 场景图 + 隐形热区
        Stack({ alignContent: Alignment.TopStart }) {
          Column() {
            Image(this.sceneImage())
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
          }
          .width('100%')
          .height('100%')
          .border({ width: 3, color: COLOR_LINE })
          .clip(true)

          ForEach(this.currentSpotList(), (spot: SceneSpot) => {
            // 隐形热区：不显示按钮与文字，点击范围覆盖对应物品整块
            Stack()
              .width(`${spot.hotW}%`)
              .height(`${spot.hotH}%`)
              .backgroundColor(Color.Transparent)
              .position({ x: `${spot.hotX}%`, y: `${spot.hotY}%` })
              .onClick(() => {
                this.onInvestigate(spot);
              })
          }, (spot: SceneSpot) => spot.id)
        }
        .width('100%')
        .layoutWeight(2)
        .margin({ left: 18, right: 18, top: 10 })

        // 底部两按钮
        Row() {
          Button('案件推理')
            .layoutWeight(1)
            .height(46)
            .backgroundColor(COLOR_INK)
            .fontColor(Color.White)
            .fontSize(14)
            .margin({ left: 18, right: 8 })
            .onClick(() => {
              this.onGotoBoard();
            })
          Button('前往下一个场景')
            .layoutWeight(1)
            .height(46)
            .backgroundColor(COLOR_INK)
            .fontColor(Color.White)
            .fontSize(14)
            .margin({ left: 8, right: 18 })
            .onClick(() => {
              this.onNextScene();
            })
        }
        .width('100%')
        .margin({ top: 16, bottom: 16 })

      }
      // 线索浮层绝对覆盖整个场景页（倒计时结束后自动入库）
      if (this.showClueCard) {
        this.ClueCard();
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  /** 线索浮层卡片 */
  @Builder ClueCard() {
    Stack() {
      Column() {
        Row() {
          Text('发现线索')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_INK)
          Blank()
          Text(`${this.countdown} 秒后存入线索板`)
            .fontSize(12)
            .fontColor(COLOR_ACCENT)
        }
        .width('100%')
        Text(this.pendingClueTitle())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_INK)
          .margin({ top: 14 })
        Text(this.pendingClueDesc())
          .fontSize(14)
          .fontColor(COLOR_INK)
          .lineHeight(22)
          .margin({ top: 10 })
        Progress({ value: CLUE_PRESENT_SECONDS - this.countdown, total: CLUE_PRESENT_SECONDS })
          .width('100%')
          .margin({ top: 16 })
      }
      .width('82%')
      .padding(20)
      .backgroundColor(COLOR_CARD)
      .border({ width: 2, color: COLOR_ACCENT })
      .borderRadius(14)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(20,26,30,0.55)')
    .alignContent(Alignment.Center)
  }

  /** 图4：线索板 */
  @Builder ClueBoardPage() {
    Column() {
      // 线索板标题框
      Row() {
        Text('线索板')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_INK)
        Blank()
        Text(`已收集 ${this.clueCount} 条`)
          .fontSize(12)
          .fontColor(COLOR_MUTED)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding(14)
      .backgroundColor(COLOR_CARD)
      .border({ width: 3, color: COLOR_LINE })
      .margin({ left: 18, right: 18, top: 10 })

      // 线索列表
      Scroll() {
        Column() {
          if (this.collectedClueIds.length === 0) {
            Text('暂无线索，回到场景中继续调查')
              .fontSize(13)
              .fontColor(COLOR_MUTED)
          } else {
            ForEach(this.collectedClueIds, (clueId: string) => {
              Row() {
                Column() {
                  Text(this.clueTitle(clueId))
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(COLOR_INK)
                  Text(this.clueDesc(clueId))
                    .fontSize(12)
                    .fontColor(COLOR_MUTED)
                    .lineHeight(18)
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                if (this.clueIsKey(clueId)) {
                  Text('关键')
                    .fontSize(10)
                    .fontColor(Color.White)
                    .backgroundColor(COLOR_ACCENT)
                    .borderRadius(4)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                }
              }
              .width('100%')
              .padding(12)
              .backgroundColor(COLOR_CARD)
              .border({ width: 1, color: '#E2DCD0' })
              .borderRadius(10)
              .margin({ bottom: 10 })
            }, (clueId: string) => clueId)
          }
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 14 })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)

      // 底部两按钮
      Row() {
        Button('继续寻找线索')
          .layoutWeight(1)
          .height(46)
          .backgroundColor(COLOR_INK)
          .fontColor(Color.White)
          .fontSize(14)
          .margin({ left: 18, right: 8 })
          .onClick(() => {
            this.onContinueSearch();
          })
        Button('推理结果')
          .layoutWeight(1)
          .height(46)
          .backgroundColor(this.canReasonFlag ? COLOR_ACCENT : '#B9B2A6')
          .fontColor(Color.White)
          .fontSize(14)
          .margin({ left: 8, right: 18 })
          .onClick(() => {
            this.onGotoReasoning();
          })
      }
      .width('100%')
      .margin({ top: 12, bottom: 16 })
    }
    .width('100%')
    .layoutWeight(1)
  }

  /** 图5：案件推理 / 结局 */
  @Builder ReasoningPage() {
    Column() {
      // 标题框
      Row() {
        Text('案件推理')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_INK)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding(14)
      .backgroundColor(COLOR_CARD)
      .border({ width: 3, color: COLOR_LINE })
      .margin({ left: 18, right: 18, top: 10 })

      // 圆角大框：选项或结局
      Column() {
        if (this.endingId.length === 0) {
          Text('根据已有线索，作出你的最终判断')
            .fontSize(14)
            .fontColor(COLOR_INK)
            .margin({ bottom: 14 })
          ForEach(SUSPECT_OPTIONS, (option: SuspectOption) => {
            Button() {
              Column() {
                Text(option.label)
                  .fontSize(15)
                  .fontColor(Color.White)
                Text(option.hint)
                  .fontSize(11)
                  .fontColor('#FFE3D6')
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .height(64)
            .backgroundColor(COLOR_INK)
            .margin({ bottom: 12 })
            .onClick(() => {
              this.onChooseSuspect(option.id);
            })
          }, (option: SuspectOption) => option.id)
        } else {
          Text(this.endingTitle())
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_ACCENT)
            .margin({ bottom: 12 })
          Text(this.endingSummary())
            .fontSize(14)
            .fontColor(COLOR_INK)
            .lineHeight(23)
        }
      }
      .width('100%')
      .layoutWeight(2)
      .padding(18)
      .backgroundColor(COLOR_CARD)
      .border({ width: 2, color: COLOR_LINE })
      .borderRadius(24)
      .margin({ left: 18, right: 18, top: 14 })

      // 底部按钮
      Row() {
        if (this.endingId.length === 0) {
          Button('继续寻找线索')
            .layoutWeight(1)
            .height(46)
            .backgroundColor(COLOR_INK)
            .fontColor(Color.White)
            .fontSize(14)
            .margin({ left: 18, right: 18 })
            .onClick(() => {
              this.onContinueSearch();
            })
        } else {
          Button('重新推理')
            .layoutWeight(1)
            .height(46)
            .backgroundColor(COLOR_INK)
            .fontColor(Color.White)
            .fontSize(14)
            .margin({ left: 18, right: 8 })
            .onClick(() => {
              this.onRevokeEnding();
            })
          Button('重开新案')
            .layoutWeight(1)
            .height(46)
            .backgroundColor(COLOR_ACCENT)
            .fontColor(Color.White)
            .fontSize(15)
            .margin({ left: 8, right: 18 })
            .onClick(() => {
              this.onRestart();
            })
        }
      }
      .width('100%')
      .margin({ top: 16, bottom: 16 })
    }
    .width('100%')
    .layoutWeight(1)
  }

  /** 底部提示条 */
  @Builder TipBar() {
    Row() {
      Text(this.tipText)
        .fontSize(13)
        .fontColor(Color.White)
    }
    .width('86%')
    .padding(12)
    .backgroundColor('rgba(43,58,66,0.92)')
    .borderRadius(10)
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: 24 })
  }

  // ==================== Builder 内取值方法（避免局部 const） ====================

  private sceneNameText(): string {
    const scene = this.currentScene();
    return scene === null ? '未知场景' : scene.name;
  }

  private sceneDescText(): string {
    const scene = this.currentScene();
    return scene === null ? '' : scene.desc;
  }

  private currentSpotList(): SceneSpot[] {
    const scene = this.currentScene();
    return scene === null ? [] : scene.spots;
  }

  private pendingClueTitle(): string {
    const clue = this.pendingClue();
    return clue === null ? '' : clue.title;
  }

  private pendingClueDesc(): string {
    const clue = this.pendingClue();
    return clue === null ? '' : clue.desc;
  }

  private clueTitle(clueId: string): string {
    const clue = this.clueById(clueId);
    return clue === null ? clueId : clue.title;
  }

  private clueDesc(clueId: string): string {
    const clue = this.clueById(clueId);
    return clue === null ? '' : clue.desc;
  }

  private clueIsKey(clueId: string): boolean {
    const clue = this.clueById(clueId);
    return clue !== null && clue.key;
  }

  private endingTitle(): string {
    const ending = this.currentEnding();
    return ending === null ? '' : ending.title;
  }

  private endingSummary(): string {
    const ending = this.currentEnding();
    return ending === null ? '' : ending.summary;
  }
}
