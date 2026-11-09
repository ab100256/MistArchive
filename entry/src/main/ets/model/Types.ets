/**
 * 迷雾档案 —— 全局数据模型定义
 * 所有业务实体在此声明 interface，避免 ArkTSCheck 报 arkts-no-untyped-obj-literals
 */

/** 页面状态机取值 */
export type PageKey = 'intro' | 'sceneSelect' | 'explore' | 'clueBoard' | 'reasoning';

/** 一条可查阅线索 */
export interface Clue {
  /** 线索唯一编号 */
  id: string;
  /** 线索标题 */
  title: string;
  /** 线索描述 */
  desc: string;
  /** 是否为关键线索（参与结局证据链判定） */
  key: boolean;
}

/** 场景内一个可点击调查位置（热点） */
export interface SceneSpot {
  /** 调查点唯一编号 */
  id: string;
  /** 位置名称，展示在热点按钮上 */
  name: string;
  /** 关联线索编号；空串表示无用线索（干扰项） */
  clueId: string;
  /** 是否为无用线索 */
  useless: boolean;
  /** 热点横坐标（场景图内百分比 0-100） */
  hotX: number;
  /** 热点纵坐标（场景图内百分比 0-100） */
  hotY: number;
  /** 隐形热区宽度（场景图内百分比 0-100），覆盖对应物品 */
  hotW: number;
  /** 隐形热区高度（场景图内百分比 0-100），覆盖对应物品 */
  hotH: number;
}

/** 一个可探索场景 */
export interface SceneInfo {
  id: string;
  name: string;
  desc: string;
  spots: SceneSpot[];
}

/** 结局定义 */
export interface EndingInfo {
  id: string;
  title: string;
  summary: string;
}

/** 推理选项（嫌疑人 / 结论） */
export interface SuspectOption {
  id: string;
  label: string;
  hint: string;
}

/** 调查动作返回结果，供 UI 决定弹层类型 */
export interface InvestigateResult {
  /** clue：获得有效线索；useless：无用线索；visited：已调查过 */
  kind: 'clue' | 'useless' | 'visited';
  clueId: string;
}

/** 存档快照（序列化写入 Preferences 的结构） */
export interface ArchivePayload {
  page: string;
  accepted: boolean;
  currentSceneId: string;
  collectedClueIds: string[];
  visitedSpotIds: string[];
  endingId: string;
  chosenSuspect: string;
  pendingClueId: string;
}
