import {
  PageKey,
  InvestigateResult,
  ArchivePayload,
  SceneSpot
} from './Types';
import {
  ALL_SCENES,
  MIN_CLUES_TO_REASON,
  TRUTH_REQUIRED_CLUES,
  findScene
} from './GameData';

/**
 * 游戏核心引擎（纯业务逻辑，不依赖 UI / Preferences，便于单元测试）。
 * 页面层所有状态变更都经过本引擎，再由 syncState 拷贝到 @State 驱动刷新。
 */
export class GameEngine {
  page: PageKey = 'intro';
  accepted: boolean = false;
  currentSceneId: string = '';
  collectedClueIds: string[] = [];
  visitedSpotIds: string[] = [];
  endingId: string = '';
  chosenSuspect: string = '';
  /** 倒计时浮层中、待入库的线索编号（随快照保存，防止进程退出丢失） */
  pendingClueId: string = '';

  /** 接受委托，进入场景选择页 */
  acceptCommission(): void {
    this.accepted = true;
    this.page = 'sceneSelect';
  }

  /** 进入某个场景调查页 */
  enterScene(sceneId: string): void {
    this.currentSceneId = sceneId;
    this.page = 'explore';
  }

  /** 回到场景选择页 */
  backToSceneSelect(): void {
    this.page = 'sceneSelect';
  }

  /** 进入线索板 */
  gotoClueBoard(): void {
    this.page = 'clueBoard';
  }

  /** 进入推理页 */
  gotoReasoning(): void {
    this.page = 'reasoning';
  }

  /**
   * 调查某个位置。
   * 已调查过 → visited；无用线索 → useless；有效线索 → clue（线索在倒计时结束后由 addClue 入库）。
   */
  investigate(spotId: string): InvestigateResult {
    if (this.visitedSpotIds.indexOf(spotId) >= 0) {
      const visitedResult: InvestigateResult = { kind: 'visited', clueId: '' };
      return visitedResult;
    }
    const spot: SceneSpot | null = this.findSpot(spotId);
    if (spot === null) {
      const missResult: InvestigateResult = { kind: 'useless', clueId: '' };
      return missResult;
    }
    this.visitedSpotIds.push(spotId);
    if (spot.useless) {
      const uselessResult: InvestigateResult = { kind: 'useless', clueId: '' };
      return uselessResult;
    }
    this.pendingClueId = spot.clueId;
    const clueResult: InvestigateResult = { kind: 'clue', clueId: spot.clueId };
    return clueResult;
  }

  /** 倒计时结束后，把线索正式保存进线索板（去重） */
  addClue(clueId: string): void {
    if (clueId.length === 0) {
      return;
    }
    if (this.collectedClueIds.indexOf(clueId) < 0) {
      this.collectedClueIds.push(clueId);
    }
    this.pendingClueId = '';
  }

  /** 已收集有效线索条数 */
  get clueCount(): number {
    return this.collectedClueIds.length;
  }

  /** 是否已持有某条线索 */
  hasClue(clueId: string): boolean {
    return this.collectedClueIds.indexOf(clueId) >= 0;
  }

  /** 是否同时持有全部给定线索 */
  hasAll(clueIds: string[]): boolean {
    for (let i = 0; i < clueIds.length; i++) {
      if (!this.hasClue(clueIds[i])) {
        return false;
      }
    }
    return true;
  }

  /** 是否达到可推理门槛（有效线索 >= 6） */
  canReason(): boolean {
    return this.collectedClueIds.length >= MIN_CLUES_TO_REASON;
  }

  /**
   * 根据选择与已有线索判定结局，写入引擎状态并返回结局编号。
   *  - 选值班同学 且 关键证据链齐全 → 真相结局；证据链未闭合 → 封存结局
   *  - 选校外人员 → 误判结局
   *  - 其余 → 封存结局
   */
  evaluateEnding(choice: string): string {
    this.chosenSuspect = choice;
    let resultId: string = 'ending_sealed';
    if (choice === 'suspect_classmate') {
      resultId = this.hasAll(TRUTH_REQUIRED_CLUES) ? 'ending_truth' : 'ending_sealed';
    } else if (choice === 'suspect_outside') {
      resultId = 'ending_misjudge';
    } else {
      resultId = 'ending_sealed';
    }
    this.endingId = resultId;
    return resultId;
  }

  /** 回到推理选项：撤销当前结局判定，保留已收集线索，可重新选择结论 */
  revokeEnding(): void {
    this.endingId = '';
    this.chosenSuspect = '';
    this.page = 'reasoning';
  }

  /** 重开新案：清空全部业务状态，回到委托页 */
  reset(): void {
    this.page = 'intro';
    this.accepted = false;
    this.currentSceneId = '';
    this.collectedClueIds = [];
    this.visitedSpotIds = [];
    this.endingId = '';
    this.chosenSuspect = '';
    this.pendingClueId = '';
  }

  /** 序列化为存档字符串 */
  serialize(): string {
    const payload: ArchivePayload = {
      page: this.page,
      accepted: this.accepted,
      currentSceneId: this.currentSceneId,
      collectedClueIds: this.collectedClueIds.slice(),
      visitedSpotIds: this.visitedSpotIds.slice(),
      endingId: this.endingId,
      chosenSuspect: this.chosenSuspect,
      pendingClueId: this.pendingClueId
    };
    return JSON.stringify(payload);
  }

  /** 从存档字符串恢复；JSON 损坏 / 字段缺失时回退为全新状态，不抛异常 */
  static deserialize(json: string): GameEngine {
    const engine: GameEngine = new GameEngine();
    if (json.length === 0) {
      return engine;
    }
    try {
      const obj: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
      const pageRaw: Object = obj['page'];
      if (typeof pageRaw === 'string') {
        engine.page = engine.toPageKey(pageRaw);
      }
      const acceptedRaw: Object = obj['accepted'];
      if (typeof acceptedRaw === 'boolean') {
        engine.accepted = acceptedRaw;
      }
      const sceneRaw: Object = obj['currentSceneId'];
      if (typeof sceneRaw === 'string') {
        engine.currentSceneId = sceneRaw;
      }
      const clueRaw: Object = obj['collectedClueIds'];
      if (Array.isArray(clueRaw)) {
        const clueList: string[] = [];
        clueRaw.forEach((item: Object) => {
          if (typeof item === 'string') {
            clueList.push(item);
          }
        });
        engine.collectedClueIds = clueList;
      }
      const visitedRaw: Object = obj['visitedSpotIds'];
      if (Array.isArray(visitedRaw)) {
        const visitedList: string[] = [];
        visitedRaw.forEach((item: Object) => {
          if (typeof item === 'string') {
            visitedList.push(item);
          }
        });
        engine.visitedSpotIds = visitedList;
      }
      const endingRaw: Object = obj['endingId'];
      if (typeof endingRaw === 'string') {
        engine.endingId = endingRaw;
      }
      const suspectRaw: Object = obj['chosenSuspect'];
      if (typeof suspectRaw === 'string') {
        engine.chosenSuspect = suspectRaw;
      }
      const pendingRaw: Object = obj['pendingClueId'];
      if (typeof pendingRaw === 'string' && pendingRaw.length > 0) {
        // 上次倒计时未结束即退出进程：恢复时把待入库线索补入线索板
        engine.pendingClueId = pendingRaw;
        engine.addClue(pendingRaw);
      }
    } catch {
      // 存档损坏：回退全新状态
      engine.reset();
    }
    return engine;
  }

  /** 把字符串归一到合法页面枚举；非法值回退 intro */
  private toPageKey(value: string): PageKey {
    if (value === 'sceneSelect' || value === 'explore' || value === 'clueBoard' || value === 'reasoning') {
      return value;
    }
    return 'intro';
  }

  /** 在全部场景中查找调查点 */
  private findSpot(spotId: string): SceneSpot | null {
    for (let s = 0; s < ALL_SCENES.length; s++) {
      const scene = ALL_SCENES[s];
      for (let i = 0; i < scene.spots.length; i++) {
        if (scene.spots[i].id === spotId) {
          return scene.spots[i];
        }
      }
    }
    return null;
  }

  /** 当前场景对象；无则返回 null */
  currentScene(): SceneSpot[] | null {
    const scene = findScene(this.currentSceneId);
    if (scene === null) {
      return null;
    }
    return scene.spots;
  }
}
