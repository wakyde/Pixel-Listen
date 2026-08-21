import 'file_picker_service.dart';

import 'file_picker_service_native.dart'
    if (dart.library.html) 'file_picker_service_web.dart';

FilePickerService createFilePickerService() => FilePickerServiceImpl();