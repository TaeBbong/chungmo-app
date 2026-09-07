/// Prompt text and response schema shared by the invitation parsers.
///
/// Pure Dart on purpose: `FirebaseAiLogicImpl` uses it inside the app, and
/// `eval/run_eval.dart` uses the very same strings when scoring the parser
/// against the hosted fixtures, so the benchmark measures the prompt that
/// actually ships. Keep Flutter and Firebase imports out of this file.
library;

/// JSON schema of a single 축의금 account, shared by both sides.
const Map<String, Object> accountJsonSchema = {
  "type": "object",
  "properties": {
    "bank": {"type": "string", "description": "Bank name, e.g. 국민"},
    "number": {
      "type": "string",
      "description": "Account number including hyphens, e.g. 123-45-6789"
    },
    "holder": {"type": "string", "description": "Account holder name"},
    "relation": {
      "type": "string",
      "description":
          "Relation of the holder, one of 신랑, 신부, 아버지, 어머니. Empty if unknown."
    }
  }
};

/// Response schema shared by the link, image and text parsers.
const Map<String, Object> scheduleResponseJsonSchema = {
  "type": "object",
  "title": "ScheduleResponse",
  "description": "ScheduleResponse from Gemini-2.5 parsed invitation",
  "properties": {
    "thumbnail": {
      "type": "string",
      "description": "Thumbnail link from response",
    },
    "groom": {
      "type": "string",
      "description": "Name of groom from response",
    },
    "bride": {
      "type": "string",
      "description": "Name of bride from response",
    },
    "location": {
      "type": "string",
      "description": "Event location from response",
    },
    "datetime": {
      "type": ["string", "null"],
      "description":
          "ISO 8601 date-time, in UTC+9(kst), e.g. 2025-12-02T10:30:00+09:00. "
              "null when the invitation has no date — never invent one."
    },
    "groomAccounts": {
      "type": "array",
      "description": "Gift money accounts of the groom's side",
      "items": accountJsonSchema,
    },
    "brideAccounts": {
      "type": "array",
      "description": "Gift money accounts of the bride's side",
      "items": accountJsonSchema,
    }
  }
};

/// Field guidelines shared by the link and image extraction prompts.
const String extractionGuidelines = '''Required data's are:
thumbnail, groom, bride, location, datetime, groomAccounts, brideAccounts
If you can't find proper data, just put empty string for that field.
For datetime, put null when the wedding date is not stated; never guess or
invent a date.

groomAccounts/brideAccounts are the gift money(축의금) accounts, usually
written under a section like "마음 전하실 곳" or "축의금 계좌".
Each account has a bank name, an account number, a holder name and the
holder's relation(신랑, 신부, 아버지, 어머니). Group them by side: the groom's
side(신랑측, including his parents) into groomAccounts, the bride's side
(신부측, including her parents) into brideAccounts.
If no account is found for a side, return an empty array for it.''';

/// Prompt for HTML text crawled from an invitation link ([parsed] is the
/// output of `extractContentWithImages`).
String linkExtractionPrompt(String? parsed) =>
    '''Extract the required wedding data from the given text and return it in pure JSON format, without any additional text or snippet tags.
          $extractionGuidelines

          Given text:
          $parsed
          ''';

/// Prompt paired with an invitation image part.
const String imageExtractionPrompt =
    '''Extract the required wedding data from the given wedding invitation image and return it in pure JSON format, without any additional text or snippet tags.
          The image is usually a screenshot of a mobile wedding invitation or a
          photo of a paper invitation, written in Korean.
          $extractionGuidelines
          Put an empty string for thumbnail; an image has no thumbnail URL.
          ''';

/// Prompt for invitation text the user pasted directly.
String textExtractionPrompt(String text) =>
    '''Extract the required wedding data from the given text and return it in pure JSON format, without any additional text or snippet tags.
          The text is usually an SMS or messenger invitation written in Korean.
          $extractionGuidelines
          Put an empty string for thumbnail; pasted text has no thumbnail URL.

          Given text:
          $text
          ''';
