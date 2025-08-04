import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'package:pachakutech_website/proto/blog_entry.pb.dart';

class ContentRepository {
  final FirebaseFirestore _db;

  ContentRepository({required FirebaseFirestore db}) : _db = db;

  Future<Map<String, dynamic>> fetchTickerMessages() async {
    try {
      final snapshot = await _db.collection('tickers').get();
      return snapshot.docs
          .map((doc) => doc.get('sections') )
          .first;
    } catch (e) {
      print("Error fetching ticker messages: $e");
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchSectionIntros() async {
    try {
      final snapshot = await _db.collection('section_intros').get();
      return snapshot.docs
          .map((doc) => doc.get('sections') )
          .first;
    } catch (e) {
      print("Error fetching ticker messages: $e");
      return {};
    }
  }

  Future<List<BlogEntry>> fetchBlogEntries(
      {required AppSection appSection, String? articleId}) async {
    var collectionName = appSection.bloggingCollection;
    return await fetchEntries(collectionName);
  }

  Future<List<BlogEntry>> fetchEntries(String collectionName) async {
      try {
      Query query = _db.collection(collectionName);
      final snapshot = await query.get();
      return snapshot.docs.map<BlogEntry>((doc) {
        final dataMap = doc.data() as Map<String, dynamic>?;

        if (dataMap == null || !dataMap.containsKey('entry')) {
          print(
              "Warning: Document ${doc.id} in $collectionName is missing expected blog_entry or data is null.");
          return BlogEntry();
        }

        final String jsonStringFromFirestore = dataMap['entry'] as String;

        try {
          // --- Deserialize using the Protobuf generated .fromJson() ---
          return BlogEntry.fromJson(jsonStringFromFirestore);
        } catch (e) {
          print(
              "Error parsing BlogEntry.fromJson for doc ${doc.id}: $e. JSON string was: $jsonStringFromFirestore");
          return BlogEntry();
        }
      }).toList();
    } catch (e, s) {
      print("Error fetching $collectionName entries: $e");
      print("Stack trace: $s");
      return [];
    }
  }

  Future<List<BlogEntry>> fetchLinkTree(
      {required AppSection appSection, String? articleId}) async {
    var collectionName = appSection.linktreeCollection;
    return fetchEntries(collectionName);
    // try {
    //   Query query =
    //       _db.collection(collectionName).orderBy('created', descending: true);
    //   final snapshot = await query.get();
    //   return snapshot.docs
    //       .map((doc) => doc.data() as Map<String, dynamic>)
    //       .toList();
    // } catch (e) {
    //   print("Error fetching $collectionName blog entries: $e");
    //   return [];
    // }
  }
}
