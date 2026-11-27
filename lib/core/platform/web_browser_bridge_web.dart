import 'dart:js_interop';
import 'dart:typed_data';

@JS('Blob')
extension type _JsBlob._(JSObject _) implements JSObject {
  external factory _JsBlob(JSArray<JSAny> parts, _JsBlobOptions options);
}

extension type _JsBlobOptions._(JSObject _) implements JSObject {
  external factory _JsBlobOptions({String type});
}

@JS('URL')
extension type _JsUrl._(JSObject _) implements JSObject {
  external static String createObjectURL(_JsBlob blob);
  external static void revokeObjectURL(String url);
}

@JS('document')
external _JsDocument get _document;

@JS('window')
external _JsWindow get _window;

extension type _JsDocument._(JSObject _) implements JSObject {
  external _JsAnchorElement createElement(String tagName);
  external _JsElement? get body;
  external void open();
  external void write(String markup);
  external void close();
}

extension type _JsElement._(JSObject _) implements JSObject {
  external void appendChild(_JsElement child);
  external void removeChild(_JsElement child);
}

extension type _JsAnchorElement._(JSObject _) implements _JsElement {
  external set href(String value);
  external set download(String value);
  external void click();
}

extension type _JsWindow._(JSObject _) implements JSObject {
  external _JsWindow? open(String url, String target);
  external _JsDocument get document;
  external void focus();
  external void print();
}

/// Triggers an immediate offline browser file download via an in-memory Blob.
void downloadBytesInBrowser(Uint8List bytes, String fileName, String mimeType) {
  final blob = _JsBlob(
    <JSAny>[bytes.toJS].toJS,
    _JsBlobOptions(type: mimeType),
  );
  final objectUrl = _JsUrl.createObjectURL(blob);
  final anchor = _document.createElement('a')
    ..href = objectUrl
    ..download = fileName;
  final body = _document.body;
  body?.appendChild(anchor);
  anchor.click();
  body?.removeChild(anchor);
  _JsUrl.revokeObjectURL(objectUrl);
}

/// Opens a clean offline print window in the browser (supporting Chrome's
/// native "Save as PDF" and physical/Wi-Fi printing).
bool printHtmlInBrowser(String html, String jobName) {
  final popup = _window.open('', '_blank');
  if (popup == null) return false;
  popup.document.open();
  popup.document.write(html);
  popup.document.close();
  popup.focus();
  popup.print();
  return true;
}
