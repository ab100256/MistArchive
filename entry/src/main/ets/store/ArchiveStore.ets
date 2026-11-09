import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

const KEY_SNAPSHOT: string = 'mist_archive_snapshot';
const STORE_NAME: string = 'mist_archive_store';

/**
 * 本地持久化封装：基于 Preferences 保存 / 读取 / 清空案件快照。
 */
export class ArchiveStore {
  private pref: preferences.Preferences | null = null;

  async init(context: common.UIAbilityContext): Promise<void> {
    this.pref = await preferences.getPreferences(context, STORE_NAME);
  }

  async saveSnapshot(json: string): Promise<void> {
    if (this.pref === null) {
      return;
    }
    await this.pref.put(KEY_SNAPSHOT, json);
    await this.pref.flush();
  }

  async loadSnapshot(): Promise<string> {
    if (this.pref === null) {
      return '';
    }
    const raw: Object = await this.pref.get(KEY_SNAPSHOT, '');
    return typeof raw === 'string' ? raw : '';
  }

  async clearSnapshot(): Promise<void> {
    if (this.pref === null) {
      return;
    }
    await this.pref.delete(KEY_SNAPSHOT);
    await this.pref.flush();
  }
}
