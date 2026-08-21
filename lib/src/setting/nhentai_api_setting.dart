import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:get/get.dart';
import 'package:jhentai/src/database/database.dart';
import 'package:jhentai/src/enum/config_enum.dart';
import 'package:jhentai/src/service/jh_service.dart';
import 'package:jhentai/src/service/local_config_service.dart';
import 'package:jhentai/src/service/log.dart';
import 'package:jhentai/src/setting/eh_setting.dart';
import 'package:jhentai/src/utils/sync_time_util.dart';

NHentaiApiSetting nhentaiApiSetting = NHentaiApiSetting();

class NHentaiApiSetting
    with JHLifeCircleBeanWithConfigStorage
    implements JHLifeCircleBean {
  final RxString apiKey = ''.obs;

  @override
  List<JHLifeCircleBean> get initDependencies =>
      super.initDependencies..add(ehSetting);

  @override
  ConfigEnum get configEnum => ConfigEnum.nhentaiApiSetting;

  @override
  void applyBeanConfig(String configString) {
    final Map<String, dynamic> map = (jsonDecode(configString) as Map)
        .cast<String, dynamic>();
    apiKey.value =
        (map['apiKey'] ?? map['nhentaiApiKey'])?.toString().trim() ?? '';
  }

  @override
  String toConfigString() => jsonEncode({'apiKey': apiKey.value});

  @override
  Future<void> doInitBean() async {
    final String? current = await localConfigService.read(
      configKey: ConfigEnum.nhentaiApiSetting,
    );
    final String legacyApiKey = ehSetting.legacyNhentaiApiKey.trim();
    if (current == null && legacyApiKey.isNotEmpty) {
      apiKey.value = legacyApiKey;
      final LocalConfig? legacyRecord = await localConfigService.readRecord(
        configKey: ConfigEnum.EHSetting,
      );
      await localConfigService.batchWrite([
        LocalConfigCompanion(
          configKey: drift.Value(ConfigEnum.nhentaiApiSetting.key),
          subConfigKey: const drift.Value(
            LocalConfigService.defaultSubConfigKey,
          ),
          value: drift.Value(toConfigString()),
          utime: drift.Value(legacyRecord?.utime ?? SyncTimeUtil.nowIso()),
        ),
      ]);
      log.info('Migrated legacy nhentai API key setting');
    }
    if (legacyApiKey.isNotEmpty) {
      ehSetting.legacyNhentaiApiKey = '';
      await ehSetting.saveBeanConfig();
    }
  }

  @override
  void doAfterBeanReady() {}

  Future<void> saveApiKey(String value) async {
    apiKey.value = value.trim();
    log.debug('saveNhentaiApiKey:configured=${apiKey.value.isNotEmpty}');
    await saveBeanConfig();
  }
}
