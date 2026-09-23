import 'package:flutter/material.dart';

import '../core/utils/constants.dart';
import '../services/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final _repo = SettingsRepository();

  String shopName = 'CyberCafe POS';
  String shopAddress = '';
  String shopPhone = '';
  String gstin = '';
  String currencySymbol = '₹';
  String invoicePrefix = 'INV';
  ThemeMode themeMode = ThemeMode.system;
  String printerName = '';
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final all = await _repo.getAll();
    shopName = all[AppSettingsKeys.shopName] ?? shopName;
    shopAddress = all[AppSettingsKeys.shopAddress] ?? shopAddress;
    shopPhone = all[AppSettingsKeys.shopPhone] ?? shopPhone;
    gstin = all[AppSettingsKeys.gstin] ?? gstin;
    currencySymbol = all[AppSettingsKeys.currencySymbol] ?? currencySymbol;
    invoicePrefix = all[AppSettingsKeys.invoicePrefix] ?? invoicePrefix;
    printerName = all[AppSettingsKeys.printerName] ?? printerName;
    final theme = all[AppSettingsKeys.themeMode] ?? 'system';
    themeMode = theme == 'light'
        ? ThemeMode.light
        : theme == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
    loading = false;
    notifyListeners();
  }

  Future<void> save({
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String gstin,
    required String currencySymbol,
    required String invoicePrefix,
    required String printerName,
  }) async {
    await _repo.setAll({
      AppSettingsKeys.shopName: shopName,
      AppSettingsKeys.shopAddress: shopAddress,
      AppSettingsKeys.shopPhone: shopPhone,
      AppSettingsKeys.gstin: gstin,
      AppSettingsKeys.currencySymbol: currencySymbol,
      AppSettingsKeys.invoicePrefix: invoicePrefix,
      AppSettingsKeys.printerName: printerName,
    });
    await load();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = mode == ThemeMode.light ? 'light' : mode == ThemeMode.dark ? 'dark' : 'system';
    await _repo.set(AppSettingsKeys.themeMode, value);
    themeMode = mode;
    notifyListeners();
  }
}
