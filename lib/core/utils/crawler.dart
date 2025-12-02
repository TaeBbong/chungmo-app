import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

/// 한글 포함 여부 체크
bool containsKorean(String text) {
  final regex = RegExp(r'[\uac00-\ud7a3]');
  return regex.hasMatch(text);
}

/// 지정된 URL에서 HTML을 가져옵니다.
Future<String?> fetchHtml(String url) async {
  try {
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return response.body;
    } else {
      // status code가 200이 아니면 null 반환
      return null;
    }
  } catch (e) {
    // 요청/타임아웃/파싱 에러 시 null
    return null;
  }
}

/// 본문 텍스트 콘텐츠를 추출하여 contentSet에 추가합니다.
void extractTextContent(Document doc, Set<String> contentSet) {
  final elements = doc.querySelectorAll(
    'p, h1, h2, h3, h4, h5, h6, li, div, script, meta, title',
  );

  for (final element in elements) {
    final text = element.text.trim();

    if (text.isNotEmpty && text.length >= 2 && containsKorean(text)) {
      contentSet.add(text);
    }
  }
}

/// 이미지 및 링크 콘텐츠를 추출하여 contentSet에 추가합니다.
void extractMediaContent(Document doc, Set<String> contentSet) {
  // <img> 태그 src
  for (final img in doc.querySelectorAll('img')) {
    final src = img.attributes['src']?.trim();
    if (src != null && src.isNotEmpty) {
      contentSet.add('[IMAGE] $src');
    }
  }

  // <link> 태그 href (CSS, favicon 등)
  for (final link in doc.querySelectorAll('link')) {
    final href = link.attributes['href']?.trim();
    if (href != null && href.isNotEmpty) {
      contentSet.add('[LINK] $href');
    }
  }

  // <a> 태그
  for (final anchor in doc.querySelectorAll('a')) {
    final href = anchor.attributes['href']?.trim() ?? '';
    final text = anchor.text.trim();

    if (href.isNotEmpty) {
      if (text.isNotEmpty) {
        contentSet.add('[ANCHOR] $text → $href');
      } else {
        contentSet.add('[ANCHOR] $href');
      }
    }
  }
}

/// 주어진 URL에서 텍스트와 미디어 콘텐츠를 추출하여 줄바꿈으로 이어 붙인 문자열을 반환합니다.
Future<String?> extractContentWithImages(String url) async {
  final html = await fetchHtml(url);
  if (html == null || html.isEmpty) {
    return null; // Python에서 `return`만 하던 것과 동일한 의미로 null 반환
  }

  final Document doc = html_parser.parse(html);

  // 불필요한 태그 제거 (Python의 soup(["style", "noscript", "link"])와 동일한 역할)
  for (final elem in doc.querySelectorAll('style, noscript, link')) {
    elem.remove();
  }

  final Set<String> extractedContent = <String>{};

  extractTextContent(doc, extractedContent);
  extractMediaContent(doc, extractedContent);

  // 정렬된 리스트를 줄바꿈으로 합쳐서 반환
  final List<String> sorted = extractedContent.toList()..sort();
  return sorted.join('\n');
}
