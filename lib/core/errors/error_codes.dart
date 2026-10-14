/// Backend error codes (SPEC §81) → user-facing messages.
///
/// The database raises these codes from RPCs (see BACKEND_SETUP.md §4).
/// UI code must always translate via [ErrorCodes.message] — never show a raw
/// backend message to the user (CLI_MASTER_PROMPT rule #10).
library;

/// Canonical backend error codes — keep in sync with SPEC §81.
abstract final class ErrorCode {
  static const String unauthenticated = 'UNAUTHENTICATED';
  static const String noBusiness = 'NO_BUSINESS';
  static const String noPermission = 'NO_PERMISSION';
  static const String shiftNotOpen = 'SHIFT_NOT_OPEN';
  static const String shiftAlreadyOpen = 'SHIFT_ALREADY_OPEN';
  static const String insufficientStock = 'INSUFFICIENT_STOCK';
  static const String negativeStockNotAllowed = 'NEGATIVE_STOCK_NOT_ALLOWED';
  static const String invalidDiscount = 'INVALID_DISCOUNT';
  static const String priceOverrideForbidden = 'PRICE_OVERRIDE_FORBIDDEN';
  static const String productNotFound = 'PRODUCT_NOT_FOUND';
  static const String productInactive = 'PRODUCT_INACTIVE';
  static const String cartEmpty = 'CART_EMPTY';
  static const String negativeTotal = 'NEGATIVE_TOTAL';
  static const String duplicateIdempotencyKey = 'DUPLICATE_IDEMPOTENCY_KEY';
  static const String duplicateBarcode = 'DUPLICATE_BARCODE';
  static const String duplicateSku = 'DUPLICATE_SKU';

  /// Category / brand / unit name already used inside the same business
  /// (partial unique indexes on `(business_id, lower(name))`).
  static const String duplicateName = 'DUPLICATE_NAME';
  static const String invalidInvoiceSequence = 'INVALID_INVOICE_SEQUENCE';
  static const String insufficientPoints = 'INSUFFICIENT_POINTS';
  static const String refundNeedsApproval = 'REFUND_NEEDS_APPROVAL';
  static const String countAlreadyApproved = 'COUNT_ALREADY_APPROVED';
  static const String transferNotInTransit = 'TRANSFER_NOT_IN_TRANSIT';
  static const String poNotApproved = 'PO_NOT_APPROVED';
  static const String supplierHasOpenBills = 'SUPPLIER_HAS_OPEN_BILLS';
  static const String useRpc = 'USE_RPC';
  static const String validationFailed = 'VALIDATION_FAILED';
  static const String internalError = 'INTERNAL_ERROR';
}

/// Translates backend/auth errors into localized-friendly plain English
/// messages. Unknown codes fall back to a generic, non-technical message.
abstract final class ErrorMessages {
  static const Map<String, String> _byCode = {
    ErrorCode.unauthenticated: 'Your session has expired. Please sign in again.',
    ErrorCode.noBusiness:
        'No business linked to this account. Please complete business setup.',
    ErrorCode.noPermission:
        'You do not have permission to perform this action.',
    ErrorCode.shiftNotOpen:
        'No open shift. Please open a shift before making a sale.',
    ErrorCode.shiftAlreadyOpen: 'You already have an open shift.',
    ErrorCode.insufficientStock: 'Not enough stock available for this item.',
    ErrorCode.negativeStockNotAllowed:
        'This sale would make stock negative, which is not allowed.',
    ErrorCode.invalidDiscount: 'The discount entered is not valid.',
    ErrorCode.priceOverrideForbidden:
        'Price override needs manager permission.',
    ErrorCode.productNotFound: 'Product not found.',
    ErrorCode.productInactive: 'This product is inactive and cannot be sold.',
    ErrorCode.cartEmpty: 'The cart is empty.',
    ErrorCode.negativeTotal: 'The sale total cannot be negative.',
    ErrorCode.duplicateIdempotencyKey: 'This sale was already recorded.',
    ErrorCode.duplicateBarcode: 'This barcode is already used by another product.',
    ErrorCode.duplicateSku: 'This SKU is already used by another product.',
    ErrorCode.duplicateName: 'An item with this name already exists.',
    ErrorCode.invalidInvoiceSequence:
        'Could not generate an invoice number. Please retry.',
    ErrorCode.insufficientPoints: 'The customer does not have enough loyalty points.',
    ErrorCode.refundNeedsApproval: 'This refund needs manager approval.',
    ErrorCode.countAlreadyApproved: 'This stock count was already approved.',
    ErrorCode.transferNotInTransit: 'This transfer is not in transit.',
    ErrorCode.poNotApproved: 'This purchase order is not approved yet.',
    ErrorCode.supplierHasOpenBills:
        'The supplier still has unpaid bills. Settle them first.',
    ErrorCode.useRpc: 'This change must go through the app workflow.',
    ErrorCode.validationFailed: 'Please check the entered values and try again.',
    ErrorCode.internalError: 'Something went wrong. Please try again.',
  };

  static const String fallback =
      'An unexpected error occurred. Please try again.';

  /// Returns the friendly message for a backend [code].
  static String message(String code) => _byCode[code] ?? fallback;

  /// Extracts a canonical code from a thrown backend error message of the
  /// form `"CODE: human text"` (see BACKEND_SETUP.md §4) or returns null.
  static String? extractCode(String raw) {
    final idx = raw.indexOf(':');
    if (idx <= 0) return null;
    final candidate = raw.substring(0, idx).trim();
    return _byCode.containsKey(candidate) ? candidate : null;
  }

  /// Best-effort translation of any thrown object.
  static String describe(Object error) {
    if (error is Exception) {
      final raw = error.toString();
      final code = extractCode(raw) ??
          (_byCode.keys.cast<String?>().firstWhere(
                (k) => raw.contains(k!),
                orElse: () => null,
              ));
      if (code != null) return message(code);
    }
    return fallback;
  }
}
