import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jhentai/src/database/database.dart';
import 'package:jhentai/src/enum/config_enum.dart';
import 'package:jhentai/src/enum/config_type_enum.dart';
import 'package:jhentai/src/model/config.dart';
import 'package:jhentai/src/service/cloud_service.dart';
import 'package:jhentai/src/service/local_config_service.dart';
import 'package:jhentai/src/service/log.dart';
import 'package:jhentai/src/service/sync_merger.dart';
import 'package:jhentai/src/setting/eh_setting.dart';
import 'package:jhentai/src/setting/nhentai_api_setting.dart';

class _SilentLogService extends LogService {
  @override
  void trace(Object msg, [bool withStack = false]) {}
  @override
  void debug(Object msg, [bool withStack = false]) {}
  @override
  void info(Object msg, [bool withStack = false]) {}
  @override
  void warning(Object msg, [Object? error, bool withStack = false]) {}
  @override
  void error(Object msg, [Object? error, StackTrace? stackTrace]) {}
}

void main() {
  group('nhentai API key cloud sync', () {
    setUp(() {
      log = _SilentLogService();
      appDb = AppDb.forTesting(NativeDatabase.memory());
      nhentaiApiSetting.apiKey.value = '';
      ehSetting.legacyNhentaiApiKey = '';
    });

    tearDown(() async {
      await appDb.close();
      nhentaiApiSetting.apiKey.value = '';
      ehSetting.legacyNhentaiApiKey = '';
    });

    test('uses a dedicated, versioned cloud config type', () {
      expect(
        CloudConfigTypeEnum.fromCode(10),
        CloudConfigTypeEnum.nhentaiApiSetting,
      );
      expect(
        CloudConfigService.configTypeVersionMap[CloudConfigTypeEnum
            .nhentaiApiSetting],
        '1.0.0',
      );
    });

    test('migrates a legacy key into the dedicated local record', () async {
      final DateTime legacyTime = DateTime.utc(2026, 8, 19, 9);
      await localConfigService.batchWrite([
        LocalConfigCompanion(
          configKey: drift.Value(ConfigEnum.EHSetting.key),
          subConfigKey: const drift.Value(
            LocalConfigService.defaultSubConfigKey,
          ),
          value: const drift.Value(
            '{"site":"EH","nhentaiApiKey":"nhk_legacy_fixture"}',
          ),
          utime: drift.Value(legacyTime.toIso8601String()),
        ),
      ]);
      ehSetting.applyBeanConfig(
        '{"site":"EH","nhentaiApiKey":"nhk_legacy_fixture"}',
      );
      final NHentaiApiSetting setting = NHentaiApiSetting();

      await setting.doInitBean();

      expect(setting.apiKey.value, 'nhk_legacy_fixture');
      expect(
        await localConfigService.read(configKey: ConfigEnum.nhentaiApiSetting),
        '{"apiKey":"nhk_legacy_fixture"}',
      );
      final String? rewrittenEhSetting = await localConfigService.read(
        configKey: ConfigEnum.EHSetting,
      );
      expect(rewrittenEhSetting, isNot(contains('nhentaiApiKey')));
      final CloudConfig? migrated = await CloudConfigService().getLocalConfig(
        CloudConfigTypeEnum.nhentaiApiSetting,
      );
      expect(migrated?.ctime, legacyTime);
    });

    test(
      'exports and imports the API key without exposing other EH settings',
      () async {
        const String localPayload = '{"apiKey":"nhk_local_fixture"}';
        await localConfigService.write(
          configKey: ConfigEnum.nhentaiApiSetting,
          value: localPayload,
        );

        final CloudConfig? exported = await CloudConfigService().getLocalConfig(
          CloudConfigTypeEnum.nhentaiApiSetting,
        );
        expect(exported, isNotNull);
        expect(exported!.config, localPayload);
        expect(exported.type, CloudConfigTypeEnum.nhentaiApiSetting);

        const String remotePayload = '{"apiKey":"nhk_remote_fixture"}';
        final DateTime remoteTime = DateTime.utc(2026, 8, 21, 12);
        await CloudConfigService().importConfig(
          CloudConfig(
            id: -1,
            shareCode: 'remote',
            identificationCode: 'remote',
            type: CloudConfigTypeEnum.nhentaiApiSetting,
            version: '1.0.0',
            config: remotePayload,
            ctime: remoteTime,
          ),
        );

        expect(nhentaiApiSetting.apiKey.value, 'nhk_remote_fixture');
        expect(
          await localConfigService.read(
            configKey: ConfigEnum.nhentaiApiSetting,
          ),
          remotePayload,
        );
        final CloudConfig? reexported = await CloudConfigService()
            .getLocalConfig(CloudConfigTypeEnum.nhentaiApiSetting);
        expect(reexported?.ctime, remoteTime);
        expect(jsonDecode(reexported!.config), <String, dynamic>{
          'apiKey': 'nhk_remote_fixture',
        });
      },
    );

    test('newest API-key setting wins whole-file conflicts', () async {
      CloudConfig config(String value, DateTime time) => CloudConfig(
        id: -1,
        shareCode: 'local',
        identificationCode: 'local',
        type: CloudConfigTypeEnum.nhentaiApiSetting,
        version: '1.0.0',
        config: value,
        ctime: time,
      );

      final MergeConfigResult result = await SyncMerger().mergeConfigType(
        CloudConfigTypeEnum.nhentaiApiSetting,
        config('{"apiKey":"nhk_old_fixture"}', DateTime.utc(2026, 8, 20)),
        config('{"apiKey":"nhk_new_fixture"}', DateTime.utc(2026, 8, 21)),
        DateTime.utc(2026, 8, 21),
        null,
      );

      expect(result.config.config, contains('nhk_new_fixture'));
    });
  });
}
