import 'package:cloud_functions/cloud_functions.dart';
import '../../home/domain/home_product.dart';

/// Submits a quote request via the storefront-submitQuoteRequest Cloud
/// Function — not a direct Firestore write. The uid is taken server-side
/// from the verified auth token (never sent by the client), and
/// firestore.rules refuses client writes to `quoteRequests` entirely
/// (see that collection's rule comment) so this callable is the only
/// path that can create one.
class QuoteRequestRepository {
  QuoteRequestRepository({FirebaseFunctions? functions}) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<void> submit({required HomeProduct product, required String note}) async {
    final callable = _functions.httpsCallable('storefront-submitQuoteRequest');
    await callable.call({
      'productTitle': product.title,
      'vendor': product.vendor,
      'note': note,
    });
  }
}

