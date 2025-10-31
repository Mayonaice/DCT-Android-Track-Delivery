import 'package:flutter/material.dart';

class StatusMaster {
  static const Map<int, StatusData> statusMap = {
    1: StatusData(
      id: 1,
      name: 'New',
      iconPath: 'assets/images/icon-status2(submitted).png',
      color: Color(0xFF6B7280), // Abu-abu
    ),
    2: StatusData(
      id: 2,
      name: 'Submitted',
      iconPath: 'assets/images/icon-status2(submitted).png',
      color: Color(0xFF3B82F6), // Biru
    ),
    3: StatusData(
      id: 3,
      name: 'Diterima Perantara',
      iconPath: 'assets/images/icon-status3(diterimaperantara).png',
      color: Color(0xFFF59E0B), // Orange
    ),
    4: StatusData(
      id: 4,
      name: 'Diterimna Target',
      iconPath: 'assets/images/icon-status5(diterima).png',
      color: Color(0xFF10B981), // Hijau
    ),
    5: StatusData(
      id: 5,
      name: 'Dikonfirmasi Penerima',
      iconPath: 'assets/images/icon-status4(dikonfirmasi).png',
      color: Color(0xFF10B981), // Hijau
    ),
  };

  static StatusData? getStatusById(int statusId) {
    return statusMap[statusId];
  }

  static List<StatusData> getAllStatuses() {
    return statusMap.values.toList();
  }

  static String getStatusName(int statusId) {
    return statusMap[statusId]?.name ?? 'Unknown Status';
  }

  static String getStatusIcon(int statusId) {
    return statusMap[statusId]?.iconPath ?? 'assets/images/icon-home-1.png';
  }

  static Color getStatusColor(int statusId) {
    return statusMap[statusId]?.color ?? Colors.grey;
  }
}

class StatusData {
  final int id;
  final String name;
  final String iconPath;
  final Color color;

  const StatusData({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.color,
  });
}

// Filter options untuk status
class StatusFilterOption {
  final String label;
  final int? statusId; // null untuk "Semua Status Pengiriman"

  const StatusFilterOption({
    required this.label,
    this.statusId,
  });

  static const List<StatusFilterOption> options = [
    StatusFilterOption(label: 'Semua Status Pengiriman', statusId: null),
    StatusFilterOption(label: 'New', statusId: 1),
    StatusFilterOption(label: 'Submitted', statusId: 2),
    StatusFilterOption(label: 'Diterima Perantara', statusId: 3),
    StatusFilterOption(label: 'Diterima Target', statusId: 4),
    StatusFilterOption(label: 'Dikonfirmasi Penerima', statusId: 5),
  ];
}

// Filter options untuk tanggal
class DateFilterOption {
  final String label;
  final DateFilterType type;
  final int? days; // untuk preset days

  const DateFilterOption({
    required this.label,
    required this.type,
    this.days,
  });

  static const List<DateFilterOption> options = [
    DateFilterOption(label: 'Semua Tanggal', type: DateFilterType.all),
    DateFilterOption(label: '30 Hari Terakhir', type: DateFilterType.preset, days: 30),
    DateFilterOption(label: '90 Hari Terakhir', type: DateFilterType.preset, days: 90),
    DateFilterOption(label: 'Pilih Tanggal Sendiri', type: DateFilterType.custom),
  ];
}

enum DateFilterType {
  all,
  preset,
  custom,
}