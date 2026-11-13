import 'dart:convert';
import 'dart:developer';

import 'package:foodly/helpers/localizations/language.dart';
import 'package:flutter/services.dart';
import 'package:get/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Translator {
  static Map<String, String>? _localizedStrings;

  /// Français : langue de référence, utilisée quand une clé n'est pas traduite.
  static Map<String, String> _fallback = {};

  static Future<Map<String, String>> _load(String code) async {
    final jsonString = await rootBundle.loadString('assets/lang/$code.json');
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(key, value.toString()));
  }

  static Future<bool> changeLanguage(Language language) async {
    try {
      if (_fallback.isEmpty) {
        _fallback = await _load('fr');
      }
      final code = language.locale.languageCode;
      _localizedStrings = code == 'fr' ? _fallback : await _load(code);
      return true;
    } catch (e) {
      log(e.toString());
    }
    return false;
  }

  // called from every screens which needs a localized text
  static String translate(String text) {
    return _localizedStrings?[text] ?? _fallback[text] ?? autoTranslate(text);
  }

  static String autoTranslate(String text) {
    // log("You need to translate this text : " + text);
    at(text);

    try {
      List<String> texts = text.split("_");
      StringBuffer stringBuffer = StringBuffer();
      for (String singleText in texts) {
        stringBuffer
            .write("${singleText[0].toUpperCase()}${singleText.substring(1)} ");
      }
      String result = stringBuffer.toString();
      return result.substring(0, result.length - 1);
    } catch (err) {
      return text;
    }
  }

  static Future<void> at(String t) async {
    // print("at");
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var data = sharedPreferences.getStringList('test_tr') ?? [];
    var set = data.toSet();
    set.add(t);
    sharedPreferences.setStringList('test_tr', set.toList());
  }

  static clearTrans() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove('test_tr');
  }

  static getUnTrans() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var data = sharedPreferences.getStringList('test_tr') ?? [];
    var set = data.toSet();
    String text = "";
    for (var value in set.toList()) {
      var p = value.replaceAll("_", " ");
      p = p.capitalize!;
      text += ('"$value": "$p",\n');
    }
    log(text);
  }
}
