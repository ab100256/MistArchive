import { describe, it, expect } from '@ohos/hypium';
import { GameEngine } from '../../../main/ets/model/GameEngine';
import { TRUTH_REQUIRED_CLUES } from '../../../main/ets/model/GameData';

/**
 * 核心引擎单元测试：覆盖正常流程、边界门槛、异常存档三类场景。
 * 运行方式：DevEco Studio 右侧 Test Runner 选中 ohosTest 用例，或命令行 hvigorw ohosTest。
 */
export default function gameEngineTest(): void {
  describe('GameEngineTest', () => {
    it('用例1-有效线索调查后可入库且计数加一', 0, () => {
      const engine: GameEngine = new GameEngine();
      const result = engine.investigate('lib_seat');
      expect(result.kind).assertEqual('clue');
      engine.addClue(result.clueId);
      expect(engine.clueCount).assertEqual(1);
      expect(engine.hasClue('lib_note')).assertTrue();
    });

    it('用例2-无用线索不进入线索板', 0, () => {
      const engine: GameEngine = new GameEngine();
      const result = engine.investigate('lib_bin');
      expect(result.kind).assertEqual('useless');
      expect(engine.clueCount).assertEqual(0);
    });

    it('用例3-重复调查同一位置不重复添加线索', 0, () => {
      const engine: GameEngine = new GameEngine();
      const first = engine.investigate('lib_seat');
      engine.addClue(first.clueId);
      const second = engine.investigate('lib_seat');
      expect(second.kind).assertEqual('visited');
      engine.addClue(second.clueId);
      expect(engine.clueCount).assertEqual(1);
    });

    it('用例4-线索达到门槛6条才允许推理（边界）', 0, () => {
      const engine: GameEngine = new GameEngine();
      const five: string[] = ['lib_note', 'lib_record', 'lib_duty', 'cor_lace', 'cor_camera'];
      five.forEach((id: string) => {
        engine.addClue(id);
      });
      expect(engine.canReason()).assertFalse();
      engine.addClue('cor_notice');
      expect(engine.clueCount).assertEqual(6);
      expect(engine.canReason()).assertTrue();
    });

    it('用例5-证据链闭合时指认同学触发真相结局', 0, () => {
      const engine: GameEngine = new GameEngine();
      TRUTH_REQUIRED_CLUES.forEach((id: string) => {
        engine.addClue(id);
      });
      const ending: string = engine.evaluateEnding('suspect_classmate');
      expect(ending).assertEqual('ending_truth');
      expect(engine.endingId).assertEqual('ending_truth');
    });

    it('用例6-证据链未闭合指认同学触发封存；指认校外人员触发误判', 0, () => {
      const engine: GameEngine = new GameEngine();
      engine.addClue('lib_note');
      engine.addClue('cor_camera');
      expect(engine.evaluateEnding('suspect_classmate')).assertEqual('ending_sealed');
      expect(engine.evaluateEnding('suspect_outside')).assertEqual('ending_misjudge');
    });

    it('用例7-重开新案后清空全部业务状态并回到委托页', 0, () => {
      const engine: GameEngine = new GameEngine();
      engine.acceptCommission();
      const result = engine.investigate('lib_seat');
      engine.addClue(result.clueId);
      engine.reset();
      expect(engine.clueCount).assertEqual(0);
      expect(engine.visitedSpotIds.length).assertEqual(0);
      expect(engine.endingId).assertEqual('');
      expect(engine.page).assertEqual('intro');
      expect(engine.accepted).assertFalse();
    });

    it('用例8-序列化反序列化状态一致（存档恢复）', 0, () => {
      const engine: GameEngine = new GameEngine();
      engine.acceptCommission();
      engine.enterScene('scene_lib');
      const result = engine.investigate('lib_seat');
      engine.addClue(result.clueId);
      const json: string = engine.serialize();
      const restored: GameEngine = GameEngine.deserialize(json);
      expect(restored.page).assertEqual('explore');
      expect(restored.currentSceneId).assertEqual('scene_lib');
      expect(restored.collectedClueIds.length).assertEqual(1);
      expect(restored.visitedSpotIds.length).assertEqual(1);
      expect(restored.accepted).assertTrue();
    });

    it('用例9-损坏的存档JSON反解时回退全新状态且不抛异常（异常）', 0, () => {
      const restored: GameEngine = GameEngine.deserialize('{{{not-a-json');
      expect(restored.clueCount).assertEqual(0);
      expect(restored.page).assertEqual('intro');
      expect(restored.accepted).assertFalse();
    });

    it('用例10-倒计时中途退出进程，恢复后待入库线索自动补入线索板', 0, () => {
      const engine: GameEngine = new GameEngine();
      engine.acceptCommission();
      const result = engine.investigate('lib_seat');
      expect(result.kind).assertEqual('clue');
      // 倒计时 20 秒尚未结束即退出：线索还在 pending，未正式入库
      expect(engine.clueCount).assertEqual(0);
      const json: string = engine.serialize();
      const restored: GameEngine = GameEngine.deserialize(json);
      expect(restored.clueCount).assertEqual(1);
      expect(restored.hasClue('lib_note')).assertTrue();
      expect(restored.pendingClueId).assertEqual('');
    });
  });
}
