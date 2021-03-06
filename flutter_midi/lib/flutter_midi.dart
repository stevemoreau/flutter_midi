import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_midi_platform_interface/platform_interface.dart';

import 'src/cache.dart';

class FlutterMidi extends FlutterMidiPlatform {
  static const MethodChannel _channel = MethodChannel('flutter_midi');

  @override
  static Future<String> setMethodCallbacks({Function onNoteEvent}) {
    print("flutter_midi: native -> flutter callbacks are set");

    _channel.setMethodCallHandler((MethodCall call) {
      print("flutter_midi: note event received from plugin ${call.method}");
      
      switch (call.method) {
        case 'midiEvent':
          onNoteEvent?.call(call.arguments as Uint8List);
          break;
          
        default:
          print("flutter_midi: native -> flutter call ignored (${call.method})");
      }
    });
  }

  /// Needed so that the sound font is loaded
  /// On iOS make sure to include the sound_font.SF2 in the Runner folder.
  /// This does not work in the simulator.
  @override
  static Future<String> prepare(
      {@required ByteData sf2, String name = "instrument.sf2"}) async {
    if (kIsWeb) return _channel.invokeMethod('prepare_midi');
    File _file = await writeToFile(sf2, name: name);
    final String result =
    await _channel.invokeMethod('prepare_midi', {"path": _file.path});
    print("flutter_midi: Prepare $result");
    return result;
  }

  /// Needed so that the sound font is loaded
  /// On iOS make sure to include the sound_font.SF2 in the Runner folder.
  /// This does not work in the simulator.
  @override
  static Future<String> changeSound(
      {@required ByteData sf2, String name = "instrument.sf2"}) async {
    File _file = await writeToFile(sf2, name: name);

    final Map<dynamic, dynamic> mapData = <dynamic, dynamic>{};
    mapData["path"] = _file.path;
    print("Path => ${_file.path}");
    final String result = await _channel.invokeMethod('change_sound', mapData);
    print("Result: $result");
    return result;
  }

  /// Unmute the device temporarly even if the mute switch is on or toggled in settings.
  @override
  static Future<String> unmute() async {
    final String result = await _channel.invokeMethod('unmute');
    return result;
  }

  /// Use this when stopping the sound onTouchUp or to cancel a long file.
  /// Not needed if playing midi onTap.
  @override
  static Future<String> stopMidiNote({
    @required int midi,
  }) async {
    final String result =
    await _channel.invokeMethod('stop_midi_note', {"note": midi});
    return result;
  }

  /// Play a midi note from the sound_font.SF2 library bundled with the application.
  /// Play a midi note in the range between 0-256
  /// Multiple notes can be played at once as seperate calls.
  @override
  static Future<String> playMidiNote({
    @required int midi,
  }) async {
    return await _channel.invokeMethod('play_midi_note', {"note": midi});
  }

  /// Play a MIDI file.
  @override
  static Future<String> loadMidiFile({
    @required String path,
  }) async {
    return await _channel.invokeMethod('load_midi_file', {"path": path});
  }

  /// Play the current MIDI file loaded.
  static Future<String> playCurrentMidiFile({
    @required double tempoFactor = 1,
  }) async {
    return await _channel.invokeMethod(
        'play_current_midi_file', {"tempoFactor": tempoFactor});
  }
}
