import 'dart:io';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:workapp_backend/00_models/timelog.dart';

class GoogleApiHandeler {
  final _spreadsheetId = '19W9GKHtWfoI0R0Yp4blP4Uz9Hcqe1vOmSHrSh2v6C8k';
  final _jsonPath = 'credentials/google_credentials.json';
  late final GoogleSheetsApi _sheetsApi;

  Future<void> init() async {
    _sheetsApi = GoogleSheetsApi(
      spreadsheetId: _spreadsheetId,
      jsonCredentialsPath: _jsonPath,
    );
    await _sheetsApi.init();
  }

  Future<void> readData() async {
    //var existingData = await _sheetsApi.readSheet('Sheet1!A1:C10');
    //print('Existing data:');
    //for (var row in existingData) {
    //  print(row);
    //}
  }

  Future<void> writeData(List<Timelog> timelogs) async {
    var oldData = timelogs;
    oldData.sort((a, b) => a.startTime.compareTo(b.startTime));
    var newData = oldData.map((t) => t.toSheetEntry()).toList();

    //var newData = [
    //  ['Name', 'Age', 'City'],
    //  ['Alice', 25, 'New York'],
    //  ['Bob', 30, 'Los Angeles'],
    //  ['Charlie', 22, 'Chicago'],
    //];
    await _sheetsApi.writeSheet('ServerOutput!B2', newData);
    //print('Sheet updated!');
  }

  Future<void> appendData() async {
    //var additionalData = [
    //  ['David', 28, 'San Francisco'],
    //];
    //await _sheetsApi.appendSheet('Sheet1!A1:C1', additionalData);
    //print('Row appended!');
  }
}

class GoogleSheetsApi {
  final String spreadsheetId;
  final String jsonCredentialsPath;
  late sheets.SheetsApi _sheetsApi;

  GoogleSheetsApi({
    required this.spreadsheetId,
    required this.jsonCredentialsPath,
  });

  /// Initialize the API client using a service account
  Future<void> init() async {
    // Read the JSON credentials from a local file
    final jsonCredentials = File(jsonCredentialsPath).readAsStringSync();

    // Parse service account credentials
    var accountCredentials = ServiceAccountCredentials.fromJson(
      jsonCredentials,
    );

    // Define the scope (full read/write access to Sheets)
    var scopes = [sheets.SheetsApi.spreadsheetsScope];

    // Get an authenticated client
    var client = await clientViaServiceAccount(accountCredentials, scopes);

    // Create the Sheets API instance
    _sheetsApi = sheets.SheetsApi(client);
  }

  /// Read a range from the sheet
  /// Example range: "Sheet1!A1:C10"
  Future<List<List<Object>>> readSheet(String range) async {
    var response = await _sheetsApi.spreadsheets.values.get(
      spreadsheetId,
      range,
    );

    // Convert nullable values to non-nullable
    return response.values
            ?.map((row) => row.map((v) => v ?? '').toList())
            .toList() ??
        [];
  }

  /// Write values to a sheet
  /// 'values' is a List of rows, each row is a List of cell values
  /// Example: [['Name', 'Age'], ['Alice', 25]]
  Future<void> writeSheet(String range, List<List<Object>> values) async {
    // Clear existing data in that range
    await _sheetsApi.spreadsheets.values.clear(
      sheets.ClearValuesRequest(),
      spreadsheetId,
      range,
    );

    // Write new values
    var request = sheets.ValueRange(range: range, values: values);
    await _sheetsApi.spreadsheets.values.update(
      request,
      spreadsheetId,
      range,
      valueInputOption: 'RAW', // Use RAW to write values exactly as-is
    );
  }

  /// Append values to the end of a sheet
  /// Does not clear existing data
  Future<void> appendSheet(String range, List<List<Object>> values) async {
    var request = sheets.ValueRange(range: range, values: values);
    await _sheetsApi.spreadsheets.values.append(
      request,
      spreadsheetId,
      range,
      valueInputOption: 'RAW',
      insertDataOption: 'INSERT_ROWS',
    );
  }
}
