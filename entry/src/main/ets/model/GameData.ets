import { Clue, SceneInfo, EndingInfo, SuspectOption } from './Types';

/** 推理通过所需的最少有效线索条数 */
export const MIN_CLUES_TO_REASON: number = 6;

/** 线索呈现倒计时（秒）：倒计时结束后线索自动保存进线索板 */
export const CLUE_PRESENT_SECONDS: number = 5;

/** 全部线索库 */
export const ALL_CLUES: Clue[] = [
  {
    id: 'lib_note',
    title: '半张便签',
    desc: '靠窗座位夹在书里的半张便签，写有借书卡号尾号 231，字迹潦草，与失物招领台登记笔迹相似。',
    key: true
  },
  {
    id: 'lib_record',
    title: '借阅记录残页',
    desc: '书架夹层里的残页：当晚 21:20 有人借出一本《嵌入式系统》，借书卡号后半截被撕去。',
    key: true
  },
  {
    id: 'lib_duty',
    title: '自习室值班表',
    desc: '公告栏值班表照片：当晚自习室值班员为周某，登记离岗时间 21:30。',
    key: false
  },
  {
    id: 'cor_lace',
    title: '门缝鞋带碎片',
    desc: '302 教室后门门缝卡着一截蓝色鞋带，与周某常穿的运动鞋鞋带同款。',
    key: true
  },
  {
    id: 'cor_camera',
    title: '被转向的监控',
    desc: '走廊监控外壳有新划痕，夜间录像角度被人为转向墙壁，恰好拍不到 302 门口。',
    key: true
  },
  {
    id: 'cor_notice',
    title: '遗失物品招领启事',
    desc: '走廊公告栏三天前已张贴平板遗失启事，至今无人认领。',
    key: false
  },
  {
    id: 'can_sleeve',
    title: '平板保护套',
    desc: '食堂失物招领台内一只黑色保护套，角落刮痕与失物机背一致。',
    key: true
  },
  {
    id: 'can_receipt',
    title: '刷卡小票',
    desc: '刷卡机旁遗留小票：21:47 有人刷餐卡进入食堂，卡号尾号 231。',
    key: true
  },
  {
    id: 'can_poster',
    title: '社团活动海报',
    desc: '门口海报栏：当晚 21:00—22:00 社团在食堂二楼活动，人员混杂。',
    key: false
  }
];

/** 三个可探索场景（每个场景 5 个调查点，其中 2 个为无用线索） */
export const ALL_SCENES: SceneInfo[] = [
  {
    id: 'scene_lib',
    name: '图书馆自习室',
    desc: '平板失踪当晚，最后有人在这里见过失主。逐个位置调查，寻找与案件相关的物证。',
    spots: [
      { id: 'lib_seat', name: '靠窗座位', clueId: 'lib_note', useless: false, hotX: 3, hotY: 27, hotW: 42, hotH: 22 },
      { id: 'lib_shelf', name: '书架夹层', clueId: 'lib_record', useless: false, hotX: 73, hotY: 8, hotW: 27, hotH: 36 },
      { id: 'lib_bin', name: '垃圾桶', clueId: '', useless: true, hotX: 5, hotY: 56, hotW: 12, hotH: 14 },
      { id: 'lib_water', name: '饮水机旁', clueId: '', useless: true, hotX: 83, hotY: 49, hotW: 16, hotH: 23 },
      { id: 'lib_board', name: '门口公告栏', clueId: 'lib_duty', useless: false, hotX: 52, hotY: 15, hotW: 21, hotH: 16 }
    ]
  },
  {
    id: 'scene_corridor',
    name: '教学楼走廊',
    desc: '302 教室外的走廊是必经之路，留意监控、门缝与转角处的异常痕迹。',
    spots: [
      { id: 'cor_backdoor', name: '302 后门', clueId: 'cor_lace', useless: false, hotX: 22, hotY: 17, hotW: 20, hotH: 42 },
      { id: 'cor_camera', name: '走廊监控', clueId: 'cor_camera', useless: false, hotX: 68, hotY: 6, hotW: 12, hotH: 10 },
      { id: 'cor_hydrant', name: '消防栓箱', clueId: '', useless: true, hotX: 5, hotY: 26, hotW: 12, hotH: 24 },
      { id: 'cor_window', name: '转角窗台', clueId: '', useless: true, hotX: 85, hotY: 38, hotW: 15, hotH: 13 },
      { id: 'cor_board', name: '走廊公告栏', clueId: 'cor_notice', useless: false, hotX: 45, hotY: 25, hotW: 34, hotH: 21 }
    ]
  },
  {
    id: 'scene_canteen',
    name: '食堂门口',
    desc: '下晚自习后人流集中，失物招领台与刷卡记录可能留下最后行踪。',
    spots: [
      { id: 'can_lost', name: '失物招领台', clueId: 'can_sleeve', useless: false, hotX: 1, hotY: 63, hotW: 32, hotH: 18 },
      { id: 'can_card', name: '刷卡机旁', clueId: 'can_receipt', useless: false, hotX: 18, hotY: 50, hotW: 9, hotH: 22 },
      { id: 'can_bike', name: '自行车棚', clueId: '', useless: true, hotX: 75, hotY: 55, hotW: 25, hotH: 34 },
      { id: 'can_bin', name: '垃圾桶', clueId: '', useless: true, hotX: 61, hotY: 60, hotW: 12, hotH: 15 },
      { id: 'can_poster', name: '门口海报栏', clueId: 'can_poster', useless: false, hotX: 54, hotY: 36, hotW: 15, hotH: 17 }
    ]
  }
];

/** 三个结局 */
export const ALL_ENDINGS: EndingInfo[] = [
  {
    id: 'ending_truth',
    title: '真相大白 · 内部同学作案',
    summary: '证据链闭合：便签字迹、借阅残页、被转向的监控与 21:47 的刷卡记录相互印证。值班员周某趁自习室离岗之机带走了平板，你在 302 储物柜夹层找回了设备，案件真相大白。'
  },
  {
    id: 'ending_misjudge',
    title: '误判 · 校外人员',
    summary: '你认定平板被校外人员顺手牵羊，但补充线索显示食堂当晚社团活动人员虽杂，却无外来人员登记。指控缺乏物证支撑，真正的行为人仍未被找到，案件只能悬置。'
  },
  {
    id: 'ending_sealed',
    title: '证据不足 · 案件封存',
    summary: '现有线索尚不足以闭合证据链，关键物证之间无法相互印证。老师决定先封存案卷，待监控恢复后再行调查。你可以继续寻找线索后重新推理。'
  }
];

/** 推理页三个选项 */
export const SUSPECT_OPTIONS: SuspectOption[] = [
  { id: 'suspect_classmate', label: '怀疑本班值班同学', hint: '需要便签、借阅残页、被转向的监控、刷卡小票相互印证' },
  { id: 'suspect_outside', label: '怀疑校外人员', hint: '主张平板被外来人员顺手牵羊' },
  { id: 'suspect_sealed', label: '暂不指认，封存案件', hint: '证据不足时先封存案卷' }
];

/** 结局 A（真相）所需的关键线索组合 */
export const TRUTH_REQUIRED_CLUES: string[] = ['lib_note', 'lib_record', 'cor_camera', 'can_receipt'];

/** 根据线索编号取线索对象；找不到返回 null */
export function findClue(clueId: string): Clue | null {
  for (let i = 0; i < ALL_CLUES.length; i++) {
    if (ALL_CLUES[i].id === clueId) {
      return ALL_CLUES[i];
    }
  }
  return null;
}

/** 根据场景编号取场景对象；找不到返回 null */
export function findScene(sceneId: string): SceneInfo | null {
  for (let i = 0; i < ALL_SCENES.length; i++) {
    if (ALL_SCENES[i].id === sceneId) {
      return ALL_SCENES[i];
    }
  }
  return null;
}

/** 根据结局编号取结局对象；找不到返回 null */
export function findEnding(endingId: string): EndingInfo | null {
  for (let i = 0; i < ALL_ENDINGS.length; i++) {
    if (ALL_ENDINGS[i].id === endingId) {
      return ALL_ENDINGS[i];
    }
  }
  return null;
}
