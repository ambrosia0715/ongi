import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/result.dart';
import '../../core/result_extension.dart';
import '../../diary/data/diary_repository.dart';

// 조건부 import
import 'dart:io' if (dart.library.html) 'dart:html' as io;

/// 백업 데이터 형식
class BackupData {
  final String version;
  final DateTime backupDate;
  final List<Map<String, dynamic>> entries;

  BackupData({
    required this.version,
    required this.backupDate,
    required this.entries,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'backupDate': backupDate.toIso8601String(),
      'entries': entries,
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as String? ?? '1.0.0',
      backupDate: json['backupDate'] != null
          ? DateTime.parse(json['backupDate'] as String)
          : DateTime.now(),
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}

/// 백업 서비스
class BackupService {
  final DiaryRepository _diaryRepository;
  static const String _backupVersion = '1.0.0';

  BackupService(this._diaryRepository);

  /// 일기 데이터를 JSON으로 백업
  Future<Result<String>> exportBackup() async {
    try {
      // 모든 일기 가져오기
      final entriesResult = await _diaryRepository.getAllEntries();
      
      return entriesResult.when(
        success: (entries) async {
          // Timestamp를 ISO 문자열로 변환
          final entriesData = entries.map((entry) {
            final map = entry.toMap();
            // Timestamp를 DateTime으로 변환 후 ISO 문자열로 변환
            if (map['createdAt'] is Timestamp) {
              map['createdAt'] = (map['createdAt'] as Timestamp).toDate().toIso8601String();
            }
            if (map['updatedAt'] is Timestamp) {
              map['updatedAt'] = (map['updatedAt'] as Timestamp).toDate().toIso8601String();
            }
            return map;
          }).toList();

          // 백업 데이터 생성
          final backupData = BackupData(
            version: _backupVersion,
            backupDate: DateTime.now(),
            entries: entriesData,
          );

          // JSON으로 변환
          final jsonString = const JsonEncoder.withIndent('  ').convert(backupData.toJson());
          
          // 파일로 저장 시도 (모바일/데스크톱, 웹 제외)
          // 실패해도 JSON 문자열을 반환하여 공유 기능에서 사용 가능
          if (!kIsWeb) {
            try {
              // path_provider가 실패할 수 있으므로 타임아웃 설정
              final directory = await getApplicationDocumentsDirectory()
                  .timeout(const Duration(seconds: 3));
              final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
              final fileName = 'ongi_backup_$timestamp.json';
              final file = io.File('${directory.path}/$fileName');
              await file.writeAsString(jsonString);
              
              // 파일 저장 성공 시 경로 반환
              return Success(file.path);
            } catch (e) {
              // 파일 저장 실패는 정상적인 폴백 상황이므로 조용히 JSON 문자열 반환
              // (공유 기능에서 JSON 문자열을 직접 사용)
            }
          }

          // 웹이거나 파일 저장 실패 시 JSON 문자열 반환 (정상적인 동작)
          return Success(jsonString);
        },
        failure: (message, error) => Failure(message, error),
      );
    } catch (e) {
      return Failure('백업을 생성하는데 실패했습니다: $e', e);
    }
  }

  /// 백업 파일을 공유 (모바일)
  /// [context]는 iOS에서 sharePositionOrigin을 설정하기 위해 필요합니다.
  Future<Result<void>> shareBackup(BuildContext? context) async {
    try {
      final backupResult = await exportBackup();
      
      return backupResult.when(
        success: (filePathOrJson) async {
          try {
            // iOS 시뮬레이터나 웹에서는 파일 공유가 제한적이므로
            // JSON 문자열을 직접 공유하는 것이 더 안정적
            // 실제 기기에서만 파일 공유 시도
            
            // sharePositionOrigin 계산 (iOS에서 필요, 특히 iPad)
            // 오류 방지를 위해 width와 height를 0이 아닌 값으로 설정
            Rect? sharePositionOrigin;
            if (context != null && !kIsWeb) {
              try {
                final mediaQuery = MediaQuery.of(context);
                final screenSize = mediaQuery.size;
                // 화면 중앙을 기준으로 설정 (iPad popover 위치)
                // width와 height를 1로 설정하여 "non-zero" 요구사항 충족
                sharePositionOrigin = Rect.fromLTWH(
                  screenSize.width / 2,
                  screenSize.height / 2,
                  1,
                  1,
                );
              } catch (e) {
                // MediaQuery를 가져올 수 없는 경우 null로 유지
                sharePositionOrigin = null;
              }
            }
            
            // 파일 경로인 경우 (실제 iOS 기기에서만 시도)
            if (!kIsWeb && 
                filePathOrJson.contains('/') && 
                !filePathOrJson.contains('\n') &&
                !filePathOrJson.contains('CoreSimulator')) {
              try {
                final file = io.File(filePathOrJson);
                if (await file.exists().timeout(const Duration(seconds: 1))) {
                  final xFile = XFile(filePathOrJson);
                  final result = await Share.shareXFiles(
                    [xFile],
                    text: '온기 일기 백업 파일',
                    sharePositionOrigin: sharePositionOrigin,
                  ).timeout(const Duration(seconds: 2));
                  
                  // 공유 결과 확인
                  if (result.status == ShareResultStatus.success) {
                    return const Success(null);
                  }
                  // 실패한 경우 다음 방법 시도
                }
              } catch (e) {
                // 파일 공유 실패는 정상적인 폴백 상황이므로 조용히 다음 방법 시도
              }
            }
            
            // 시뮬레이터나 파일 공유 실패 시: JSON 문자열을 직접 공유 (가장 안정적)
            final result = await Share.share(
              filePathOrJson,
              subject: '온기 일기 백업',
              sharePositionOrigin: sharePositionOrigin,
            );
            
            // 공유 결과 확인
            if (result.status == ShareResultStatus.success) {
              return const Success(null);
            } else {
              // 사용자가 공유 시트를 닫은 경우도 성공으로 처리
              return const Success(null);
            }
          } catch (e) {
            return Failure('백업 파일을 공유하는데 실패했습니다: $e', e);
          }
        },
        failure: (message, error) => Failure(message, error),
      );
    } catch (e) {
      return Failure('백업을 공유하는데 실패했습니다: $e', e);
    }
  }

  /// 백업 파일에서 일기 데이터 복원
  Future<Result<int>> importBackup() async {
    try {
      // 파일 선택 (iOS에서도 작동하도록 설정 개선)
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
          withData: true,
          allowMultiple: false,
          allowCompression: false,
        );
      } catch (e) {
        // iOS에서 파일 선택 실패 시 다른 방법 시도
        print('FilePicker 오류: $e');
        // iOS에서는 withData 없이 시도
        try {
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['json'],
            withData: false,
            allowMultiple: false,
          );
        } catch (e2) {
          return Failure('파일 선택 중 오류가 발생했습니다: $e2', e2);
        }
      }

      if (result == null || result.files.isEmpty) {
        return const Failure('파일이 선택되지 않았습니다.');
      }

      final file = result.files.first;
      String jsonString;

      if (file.bytes != null) {
        // 파일 데이터가 메모리에 있는 경우
        jsonString = utf8.decode(file.bytes!);
      } else if (file.path != null && !kIsWeb) {
        // 파일 경로가 있는 경우 (웹 제외)
        try {
          final fileData = io.File(file.path!);
          jsonString = await fileData.readAsString();
        } catch (e) {
          return Failure('파일을 읽을 수 없습니다: $e', e);
        }
      } else {
        return const Failure('파일을 읽을 수 없습니다.');
      }

      // JSON 파싱
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final backupData = BackupData.fromJson(jsonData);

      // 일기 데이터 변환
      final entries = backupData.entries.map((entryMap) {
        // ISO 문자열을 DateTime으로 변환
        if (entryMap['createdAt'] is String) {
          entryMap['createdAt'] = Timestamp.fromDate(DateTime.parse(entryMap['createdAt'] as String));
        }
        if (entryMap['updatedAt'] is String) {
          entryMap['updatedAt'] = Timestamp.fromDate(DateTime.parse(entryMap['updatedAt'] as String));
        }
        return DiaryEntry.fromMap(entryMap);
      }).toList();

      // Firestore에 저장
      final saveResult = await _diaryRepository.saveEntries(entries);
      
      return saveResult.when(
        success: (_) => Success(entries.length),
        failure: (message, error) => Failure(message, error),
      );
    } catch (e) {
      return Failure('백업을 복원하는데 실패했습니다: $e', e);
    }
  }
}

