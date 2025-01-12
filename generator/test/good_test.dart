import 'test_util.dart';

void main() {
  const directory = 'test/good_test_data';
  getListOfTestFiles(directory).forEach((inputFile, expectedFile) {
    executeTest(getTestName(inputFile), () async {
      await generatorTestBuilder(directory, inputFile, expectedFile);
    });
  });
}
