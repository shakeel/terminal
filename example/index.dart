import 'dart:html';
import 'dart:async';
import 'dart:typed_data';
import 'package:terminal/terminal.dart';
import 'package:terminal/theme.dart';

WebSocket ws;
Terminal term;

void main() {
  term = new Terminal(querySelector('#console'))
    ..scrollSpeed = 3
    ..cursorBlink = true
    ..theme = new Theme.SolarizedDark();

  List<int> size = term.currentSize();
  int rows = size[0];
  int cols = size[1];
  print('Terminal spawned with size: $rows x $cols');
  print('└─> cmdr-pty size should be set to $rows x ${cols - 1}');

  initWebSocket('ws://localhost:12061/pty');

  // Terminal input.
  term.stdin.stream.listen((data) {
    ws.sendByteBuffer(new Uint8List.fromList(data).buffer);
  });
}

void initWebSocket(String url, [int retrySeconds = 2]) {
    bool encounteredError = false;

    ws = new WebSocket(url);
    ws.binaryType = "arraybuffer";

    ws.onOpen.listen((e) {
      print('Terminal connected to server with status ${ws.readyState}.');
    });

    // Terminal output.
    ws.onMessage.listen((e) {
      ByteBuffer buf = e.data;
      term.stdout.add(buf.asUint8List());
    });

    ws.onClose.listen((e) {
      print('Terminal disconnected due to CLOSE.');
    });

    ws.onError.listen((e) {
      print('Terminal disconnected due to ERROR. Retrying...');
      if (!encounteredError) {
        new Timer(new Duration(seconds:retrySeconds), () => initWebSocket(url, 4));
      }
      encounteredError = true;
    });
  }