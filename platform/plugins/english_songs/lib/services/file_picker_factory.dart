import 'file_picker_service.dart';

import 'file_picker_service_native.dart'
    if (dart.library.js_interop) 'file_picker_service_web.dart';

FilePickerService createFilePickerService() => FilePickerServiceImpl();