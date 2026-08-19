import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediahub/domain/repositories/media_repository.dart';
import 'package:mediahub/features/library/presentation/controllers/library_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockMediaRepository extends Mock implements MediaRepository {}
class MockRef extends Mock implements Ref {}

void main() {
  late MockMediaRepository mockRepository;
  late MockRef mockRef;
  late LibraryController controller;

  setUp(() {
    mockRepository = MockMediaRepository();
    mockRef = MockRef();
    controller = LibraryController(mockRepository, mockRef);
  });

  test('Initial LibraryState has default values', () {
    expect(controller.state.isScanning, false);
    expect(controller.state.permissionGranted, true);
    expect(controller.state.errorMessage, null);
    expect(controller.state.statusMessage, null);
  });

  test('LibraryState copyWith updates state correctly', () {
    final state = const LibraryState();
    final updated = state.copyWith(isScanning: true, statusMessage: 'Scanning...');
    expect(updated.isScanning, true);
    expect(updated.statusMessage, 'Scanning...');
    expect(updated.permissionGranted, true);
  });
}
