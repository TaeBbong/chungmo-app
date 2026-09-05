import 'package:chungmo/domain/entities/invitation_image.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/domain/usecases/analyze_image_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockScheduleRepository repository;
  late AnalyzeImageUsecase usecase;

  final Schedule schedule = Schedule(
    link: 'image://1',
    thumbnail: '',
    groom: 'g',
    bride: 'b',
    date: DateTime(2026, 10, 10),
    location: 'l',
  );

  setUp(() {
    repository = MockScheduleRepository();
    usecase = AnalyzeImageUsecase(repository);
  });

  test('downscales an oversized capture before handing it to the repository',
      () async {
    // The usecase is the single entry point for image parses, so the
    // preprocessing must apply to every caller here, not per call site.
    InvitationImage? received;
    when(repository.analyzeImage(any)).thenAnswer((invocation) async {
      received = invocation.positionalArguments.first as InvitationImage;
      return schedule;
    });

    await usecase.execute(InvitationImage(
      bytes: img.encodePng(img.Image(width: 3200, height: 1600)),
      mimeType: 'image/png',
    ));

    expect(img.decodeImage(received!.bytes)!.width, 1600);
    expect(received!.mimeType, 'image/jpeg');
  });
}
