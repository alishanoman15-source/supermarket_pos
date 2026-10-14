import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Supermarket POS'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data for this period.'**
  String get noData;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this. Pull to retry.'**
  String get genericError;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your store'**
  String get signInSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Create one'**
  String get noAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating account…'**
  String get creatingAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @accountDeactivated.
  ///
  /// In en, this message translates to:
  /// **'This account has been deactivated. Contact your business administrator to reactivate it.'**
  String get accountDeactivated;

  /// No description provided for @confirmEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Account created. Check your email to confirm it, then sign in.'**
  String get confirmEmailSent;

  /// No description provided for @accountExists.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account.'**
  String get accountExists;

  /// No description provided for @accountExistsHelp.
  ///
  /// In en, this message translates to:
  /// **'Sign in instead. Invited staff: use the password you set when accepting the invite, or ask the owner to reset it from Team.'**
  String get accountExistsHelp;

  /// No description provided for @goToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Go to sign in'**
  String get goToSignIn;

  /// No description provided for @invalidLogin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Check both and try again.'**
  String get invalidLogin;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @resetPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset link.'**
  String get resetPasswordHelp;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'If that email exists, a reset link is on its way.'**
  String get resetSent;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @passwordResetDone.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Share the new password with this team member.'**
  String get passwordResetDone;

  /// No description provided for @resetPasswordFor.
  ///
  /// In en, this message translates to:
  /// **'Set a new password for this team member. They can change it after signing in.'**
  String get resetPasswordFor;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get nameRequired;

  /// No description provided for @businessSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your business'**
  String get businessSetupTitle;

  /// No description provided for @businessSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This creates your business, first branch and owner account.'**
  String get businessSetupSubtitle;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get businessName;

  /// No description provided for @branchName.
  ///
  /// In en, this message translates to:
  /// **'Branch name'**
  String get branchName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get saveAndContinue;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @revenueToday.
  ///
  /// In en, this message translates to:
  /// **'Revenue today'**
  String get revenueToday;

  /// No description provided for @transactionsToday.
  ///
  /// In en, this message translates to:
  /// **'Transactions today'**
  String get transactionsToday;

  /// No description provided for @grossProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross profit'**
  String get grossProfit;

  /// No description provided for @lowStockItems.
  ///
  /// In en, this message translates to:
  /// **'Low stock items'**
  String get lowStockItems;

  /// No description provided for @topProducts.
  ///
  /// In en, this message translates to:
  /// **'Top products'**
  String get topProducts;

  /// No description provided for @noSalesYet.
  ///
  /// In en, this message translates to:
  /// **'No sales yet for this period.'**
  String get noSalesYet;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @vsYesterday.
  ///
  /// In en, this message translates to:
  /// **'vs previous period'**
  String get vsYesterday;

  /// No description provided for @pos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get pos;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @purchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get purchases;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get signedInAs;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'This module arrives in a later sprint.'**
  String get comingSoon;

  /// No description provided for @catalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalog;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @sellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling price'**
  String get sellingPrice;

  /// No description provided for @purchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase price'**
  String get purchasePrice;

  /// No description provided for @taxRate.
  ///
  /// In en, this message translates to:
  /// **'Tax rate (%)'**
  String get taxRate;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search by name, SKU or barcode'**
  String get searchProducts;

  /// No description provided for @noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products yet. Add your first product.'**
  String get noProducts;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No matching products.'**
  String get noResults;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get required;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get invalidNumber;

  /// No description provided for @generateBarcode.
  ///
  /// In en, this message translates to:
  /// **'Generate barcode'**
  String get generateBarcode;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @brands.
  ///
  /// In en, this message translates to:
  /// **'Brands'**
  String get brands;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @addBrand.
  ///
  /// In en, this message translates to:
  /// **'Add brand'**
  String get addBrand;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @editBrand.
  ///
  /// In en, this message translates to:
  /// **'Edit brand'**
  String get editBrand;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @reorderLevel.
  ///
  /// In en, this message translates to:
  /// **'Reorder level'**
  String get reorderLevel;

  /// No description provided for @weightBased.
  ///
  /// In en, this message translates to:
  /// **'Sold by weight'**
  String get weightBased;

  /// No description provided for @imageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrl;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this item?'**
  String get confirmDelete;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @productDetail.
  ///
  /// In en, this message translates to:
  /// **'Product detail'**
  String get productDetail;

  /// No description provided for @stockOnHand.
  ///
  /// In en, this message translates to:
  /// **'Stock on hand'**
  String get stockOnHand;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @margin.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get margin;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get unitPrice;

  /// No description provided for @barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode label'**
  String get barcodeLabel;

  /// No description provided for @printLabel.
  ///
  /// In en, this message translates to:
  /// **'Print label'**
  String get printLabel;

  /// No description provided for @copies.
  ///
  /// In en, this message translates to:
  /// **'Copies'**
  String get copies;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @recentMovements.
  ///
  /// In en, this message translates to:
  /// **'Recent movements'**
  String get recentMovements;

  /// No description provided for @stockCounts.
  ///
  /// In en, this message translates to:
  /// **'Stock counts'**
  String get stockCounts;

  /// No description provided for @stockTransfers.
  ///
  /// In en, this message translates to:
  /// **'Stock transfers'**
  String get stockTransfers;

  /// No description provided for @stockCountEntry.
  ///
  /// In en, this message translates to:
  /// **'Stock count entry'**
  String get stockCountEntry;

  /// No description provided for @startStockCount.
  ///
  /// In en, this message translates to:
  /// **'Start stock count'**
  String get startStockCount;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @systemQty.
  ///
  /// In en, this message translates to:
  /// **'System qty'**
  String get systemQty;

  /// No description provided for @movements.
  ///
  /// In en, this message translates to:
  /// **'Movements'**
  String get movements;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStock;

  /// No description provided for @adjustStock.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get adjustStock;

  /// No description provided for @qtyDelta.
  ///
  /// In en, this message translates to:
  /// **'Quantity change'**
  String get qtyDelta;

  /// No description provided for @qtyDeltaHelp.
  ///
  /// In en, this message translates to:
  /// **'Use a negative number to remove stock'**
  String get qtyDeltaHelp;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @toBranch.
  ///
  /// In en, this message translates to:
  /// **'To branch'**
  String get toBranch;

  /// No description provided for @newTransfer.
  ///
  /// In en, this message translates to:
  /// **'New transfer'**
  String get newTransfer;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get qty;

  /// No description provided for @batches.
  ///
  /// In en, this message translates to:
  /// **'Batches & expiry'**
  String get batches;

  /// No description provided for @batchNo.
  ///
  /// In en, this message translates to:
  /// **'Batch number'**
  String get batchNo;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get expiryDate;

  /// No description provided for @batchQty.
  ///
  /// In en, this message translates to:
  /// **'Batch qty'**
  String get batchQty;

  /// No description provided for @noBatches.
  ///
  /// In en, this message translates to:
  /// **'No tracked batches for this branch.'**
  String get noBatches;

  /// No description provided for @shifts.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get shifts;

  /// No description provided for @openShift.
  ///
  /// In en, this message translates to:
  /// **'Open shift'**
  String get openShift;

  /// No description provided for @closeShift.
  ///
  /// In en, this message translates to:
  /// **'Close shift'**
  String get closeShift;

  /// No description provided for @closedShift.
  ///
  /// In en, this message translates to:
  /// **'Closed shift'**
  String get closedShift;

  /// No description provided for @openingFloat.
  ///
  /// In en, this message translates to:
  /// **'Opening float'**
  String get openingFloat;

  /// No description provided for @countedCash.
  ///
  /// In en, this message translates to:
  /// **'Counted cash'**
  String get countedCash;

  /// No description provided for @expectedCash.
  ///
  /// In en, this message translates to:
  /// **'Expected cash'**
  String get expectedCash;

  /// No description provided for @variance.
  ///
  /// In en, this message translates to:
  /// **'Variance'**
  String get variance;

  /// No description provided for @varianceReasonHelp.
  ///
  /// In en, this message translates to:
  /// **'Required when the variance is outside tolerance'**
  String get varianceReasonHelp;

  /// No description provided for @cashDrawer.
  ///
  /// In en, this message translates to:
  /// **'Cash drawer'**
  String get cashDrawer;

  /// No description provided for @cashIn.
  ///
  /// In en, this message translates to:
  /// **'Cash in'**
  String get cashIn;

  /// No description provided for @cashOut.
  ///
  /// In en, this message translates to:
  /// **'Cash out'**
  String get cashOut;

  /// No description provided for @drawerIn.
  ///
  /// In en, this message translates to:
  /// **'Drawer in'**
  String get drawerIn;

  /// No description provided for @drawerOut.
  ///
  /// In en, this message translates to:
  /// **'Drawer out'**
  String get drawerOut;

  /// No description provided for @recordMovement.
  ///
  /// In en, this message translates to:
  /// **'Record movement'**
  String get recordMovement;

  /// No description provided for @shiftSummary.
  ///
  /// In en, this message translates to:
  /// **'Shift summary'**
  String get shiftSummary;

  /// No description provided for @openedAt.
  ///
  /// In en, this message translates to:
  /// **'Opened at'**
  String get openedAt;

  /// No description provided for @closedAt.
  ///
  /// In en, this message translates to:
  /// **'Closed at'**
  String get closedAt;

  /// No description provided for @scanOrSearch.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode or search products'**
  String get scanOrSearch;

  /// No description provided for @searchCustomer.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone or email'**
  String get searchCustomer;

  /// No description provided for @guestCustomer.
  ///
  /// In en, this message translates to:
  /// **'Guest customer'**
  String get guestCustomer;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartEmpty;

  /// No description provided for @emptyTotal.
  ///
  /// In en, this message translates to:
  /// **'The cart total is zero'**
  String get emptyTotal;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear cart'**
  String get clearCart;

  /// No description provided for @confirmClearCart.
  ///
  /// In en, this message translates to:
  /// **'Remove every item from the cart?'**
  String get confirmClearCart;

  /// No description provided for @cartHeld.
  ///
  /// In en, this message translates to:
  /// **'Cart held. Resume it from Held carts.'**
  String get cartHeld;

  /// No description provided for @hold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get hold;

  /// No description provided for @heldCarts.
  ///
  /// In en, this message translates to:
  /// **'Held carts'**
  String get heldCarts;

  /// No description provided for @noHeldCarts.
  ///
  /// In en, this message translates to:
  /// **'No held carts on this device.'**
  String get noHeldCarts;

  /// No description provided for @lineOptions.
  ///
  /// In en, this message translates to:
  /// **'Line options'**
  String get lineOptions;

  /// No description provided for @lineDiscount.
  ///
  /// In en, this message translates to:
  /// **'Line discount'**
  String get lineDiscount;

  /// No description provided for @priceOverride.
  ///
  /// In en, this message translates to:
  /// **'Price override'**
  String get priceOverride;

  /// No description provided for @permissionRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Requires permission; checked on the server'**
  String get permissionRequiredHint;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @exact.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get exact;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @addPayment.
  ///
  /// In en, this message translates to:
  /// **'Add payment'**
  String get addPayment;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @noPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'Add at least one payment to continue.'**
  String get noPaymentsYet;

  /// No description provided for @completeSale.
  ///
  /// In en, this message translates to:
  /// **'Complete sale'**
  String get completeSale;

  /// No description provided for @payCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get payCash;

  /// No description provided for @payCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get payCard;

  /// No description provided for @payWallet.
  ///
  /// In en, this message translates to:
  /// **'Mobile wallet'**
  String get payWallet;

  /// No description provided for @payOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get payOther;

  /// No description provided for @cartDiscount.
  ///
  /// In en, this message translates to:
  /// **'Cart discount'**
  String get cartDiscount;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found.'**
  String get productNotFound;

  /// No description provided for @productInactive.
  ///
  /// In en, this message translates to:
  /// **'This product is inactive and cannot be sold.'**
  String get productInactive;

  /// No description provided for @saleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sale completed'**
  String get saleCompleted;

  /// No description provided for @salePendingSync.
  ///
  /// In en, this message translates to:
  /// **'Sale saved offline — waiting to sync'**
  String get salePendingSync;

  /// No description provided for @saleSyncNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Sale saved locally — sync needs review'**
  String get saleSyncNeedsReview;

  /// No description provided for @offlineLocalReference.
  ///
  /// In en, this message translates to:
  /// **'Temporary local reference'**
  String get offlineLocalReference;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @changeDue.
  ///
  /// In en, this message translates to:
  /// **'Change due'**
  String get changeDue;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print receipt'**
  String get printReceipt;

  /// No description provided for @cameraScanner.
  ///
  /// In en, this message translates to:
  /// **'Camera scanner'**
  String get cameraScanner;

  /// No description provided for @scanBarcodeHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a barcode'**
  String get scanBarcodeHint;

  /// No description provided for @noOpenShiftHint.
  ///
  /// In en, this message translates to:
  /// **'Open a shift before selling.'**
  String get noOpenShiftHint;

  /// No description provided for @salesHistory.
  ///
  /// In en, this message translates to:
  /// **'Sales history'**
  String get salesHistory;

  /// No description provided for @searchInvoice.
  ///
  /// In en, this message translates to:
  /// **'Search by invoice number'**
  String get searchInvoice;

  /// No description provided for @statusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get statusAll;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get statusReturned;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @saleDetail.
  ///
  /// In en, this message translates to:
  /// **'Sale detail'**
  String get saleDetail;

  /// No description provided for @returnItems.
  ///
  /// In en, this message translates to:
  /// **'Return items'**
  String get returnItems;

  /// No description provided for @returns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get returns;

  /// No description provided for @cancelSale.
  ///
  /// In en, this message translates to:
  /// **'Cancel sale'**
  String get cancelSale;

  /// No description provided for @saleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sale cancelled and stock restored.'**
  String get saleCancelled;

  /// No description provided for @reasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a reason'**
  String get reasonRequired;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get sold;

  /// No description provided for @returned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returned;

  /// No description provided for @refundMethod.
  ///
  /// In en, this message translates to:
  /// **'Refund method'**
  String get refundMethod;

  /// No description provided for @submitReturn.
  ///
  /// In en, this message translates to:
  /// **'Submit return'**
  String get submitReturn;

  /// No description provided for @returnTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Return quantity exceeds what is left to return.'**
  String get returnTooLarge;

  /// No description provided for @selectAtLeastOneItem.
  ///
  /// In en, this message translates to:
  /// **'Select at least one item to return.'**
  String get selectAtLeastOneItem;

  /// No description provided for @suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @addSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add supplier'**
  String get addSupplier;

  /// No description provided for @editSupplier.
  ///
  /// In en, this message translates to:
  /// **'Edit supplier'**
  String get editSupplier;

  /// No description provided for @supplierDetail.
  ///
  /// In en, this message translates to:
  /// **'Supplier detail'**
  String get supplierDetail;

  /// No description provided for @supplierName.
  ///
  /// In en, this message translates to:
  /// **'Supplier name'**
  String get supplierName;

  /// No description provided for @contactPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact person'**
  String get contactPerson;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalance;

  /// No description provided for @paySupplier.
  ///
  /// In en, this message translates to:
  /// **'Pay supplier'**
  String get paySupplier;

  /// No description provided for @supplierPayment.
  ///
  /// In en, this message translates to:
  /// **'Supplier payment'**
  String get supplierPayment;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get bankTransfer;

  /// No description provided for @noSuppliers.
  ///
  /// In en, this message translates to:
  /// **'No suppliers yet. Add your first supplier.'**
  String get noSuppliers;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get addCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get editCustomer;

  /// No description provided for @customerDetail.
  ///
  /// In en, this message translates to:
  /// **'Customer detail'**
  String get customerDetail;

  /// No description provided for @noCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers yet. Add your first customer.'**
  String get noCustomers;

  /// No description provided for @creditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get creditLimit;

  /// No description provided for @loyaltyPoints.
  ///
  /// In en, this message translates to:
  /// **'Loyalty points'**
  String get loyaltyPoints;

  /// No description provided for @loyaltyTransactions.
  ///
  /// In en, this message translates to:
  /// **'Loyalty transactions'**
  String get loyaltyTransactions;

  /// No description provided for @earn.
  ///
  /// In en, this message translates to:
  /// **'Earn'**
  String get earn;

  /// No description provided for @redeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get redeem;

  /// No description provided for @adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get adjust;

  /// No description provided for @balanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance after'**
  String get balanceAfter;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @noLoyaltyActivity.
  ///
  /// In en, this message translates to:
  /// **'No loyalty activity for this customer.'**
  String get noLoyaltyActivity;

  /// No description provided for @purchaseOrders.
  ///
  /// In en, this message translates to:
  /// **'Purchase orders'**
  String get purchaseOrders;

  /// No description provided for @purchaseOrder.
  ///
  /// In en, this message translates to:
  /// **'Purchase order'**
  String get purchaseOrder;

  /// No description provided for @newPurchaseOrder.
  ///
  /// In en, this message translates to:
  /// **'New purchase order'**
  String get newPurchaseOrder;

  /// No description provided for @poNumber.
  ///
  /// In en, this message translates to:
  /// **'PO number'**
  String get poNumber;

  /// No description provided for @expectedDate.
  ///
  /// In en, this message translates to:
  /// **'Expected date'**
  String get expectedDate;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @approvedStatus.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvedStatus;

  /// No description provided for @partiallyReceived.
  ///
  /// In en, this message translates to:
  /// **'Partially received'**
  String get partiallyReceived;

  /// No description provided for @receivedStatus.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get receivedStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledStatus;

  /// No description provided for @approveOrder.
  ///
  /// In en, this message translates to:
  /// **'Approve order'**
  String get approveOrder;

  /// No description provided for @goodsReceive.
  ///
  /// In en, this message translates to:
  /// **'Goods receive'**
  String get goodsReceive;

  /// No description provided for @receiveGoods.
  ///
  /// In en, this message translates to:
  /// **'Receive goods'**
  String get receiveGoods;

  /// No description provided for @orderedQty.
  ///
  /// In en, this message translates to:
  /// **'Ordered'**
  String get orderedQty;

  /// No description provided for @receivedQty.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get receivedQty;

  /// No description provided for @unitCost.
  ///
  /// In en, this message translates to:
  /// **'Unit cost'**
  String get unitCost;

  /// No description provided for @lineTotal.
  ///
  /// In en, this message translates to:
  /// **'Line total'**
  String get lineTotal;

  /// No description provided for @purchaseBills.
  ///
  /// In en, this message translates to:
  /// **'Purchase bills'**
  String get purchaseBills;

  /// No description provided for @billNumber.
  ///
  /// In en, this message translates to:
  /// **'Bill number'**
  String get billNumber;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @partiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially paid'**
  String get partiallyPaid;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @orderLines.
  ///
  /// In en, this message translates to:
  /// **'Order lines'**
  String get orderLines;

  /// No description provided for @addLine.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get addLine;

  /// No description provided for @alreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'This item is already on the list.'**
  String get alreadyAdded;

  /// No description provided for @noPurchaseOrders.
  ///
  /// In en, this message translates to:
  /// **'No purchase orders yet.'**
  String get noPurchaseOrders;

  /// No description provided for @noBills.
  ///
  /// In en, this message translates to:
  /// **'No purchase bills yet.'**
  String get noBills;

  /// No description provided for @orderCreated.
  ///
  /// In en, this message translates to:
  /// **'Purchase order created'**
  String get orderCreated;

  /// No description provided for @orderApprovedMsg.
  ///
  /// In en, this message translates to:
  /// **'Purchase order approved'**
  String get orderApprovedMsg;

  /// No description provided for @goodsReceived.
  ///
  /// In en, this message translates to:
  /// **'Goods received and stock updated'**
  String get goodsReceived;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get editExpense;

  /// No description provided for @expenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Expense categories'**
  String get expenseCategories;

  /// No description provided for @addExpenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addExpenseCategory;

  /// No description provided for @payee.
  ///
  /// In en, this message translates to:
  /// **'Payee'**
  String get payee;

  /// No description provided for @paidAt.
  ///
  /// In en, this message translates to:
  /// **'Paid at'**
  String get paidAt;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded for this period.'**
  String get noExpenses;

  /// No description provided for @noExpenseCategories.
  ///
  /// In en, this message translates to:
  /// **'No expense categories yet.'**
  String get noExpenseCategories;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// No description provided for @promotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get promotion;

  /// No description provided for @addPromotion.
  ///
  /// In en, this message translates to:
  /// **'Add promotion'**
  String get addPromotion;

  /// No description provided for @editPromotion.
  ///
  /// In en, this message translates to:
  /// **'Edit promotion'**
  String get editPromotion;

  /// No description provided for @promoType.
  ///
  /// In en, this message translates to:
  /// **'Promotion type'**
  String get promoType;

  /// No description provided for @percentOff.
  ///
  /// In en, this message translates to:
  /// **'Percent off'**
  String get percentOff;

  /// No description provided for @fixedOff.
  ///
  /// In en, this message translates to:
  /// **'Fixed amount off'**
  String get fixedOff;

  /// No description provided for @buyXGetY.
  ///
  /// In en, this message translates to:
  /// **'Buy X get Y'**
  String get buyXGetY;

  /// No description provided for @pricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Special price per unit'**
  String get pricePerUnit;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @minQty.
  ///
  /// In en, this message translates to:
  /// **'Minimum qty'**
  String get minQty;

  /// No description provided for @freeQty.
  ///
  /// In en, this message translates to:
  /// **'Free qty'**
  String get freeQty;

  /// No description provided for @startsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at'**
  String get startsAt;

  /// No description provided for @endsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends at'**
  String get endsAt;

  /// No description provided for @stackable.
  ///
  /// In en, this message translates to:
  /// **'Can stack with other promotions'**
  String get stackable;

  /// No description provided for @noPromotions.
  ///
  /// In en, this message translates to:
  /// **'No promotions yet.'**
  String get noPromotions;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get noNotifications;

  /// No description provided for @notificationDetail.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationDetail;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update profile'**
  String get updateProfile;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @avatarUrl.
  ///
  /// In en, this message translates to:
  /// **'Avatar URL'**
  String get avatarUrl;

  /// No description provided for @globalSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get globalSearch;

  /// No description provided for @searchEverything.
  ///
  /// In en, this message translates to:
  /// **'Search products, customers, suppliers, invoices'**
  String get searchEverything;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing matched your search.'**
  String get noSearchResults;

  /// No description provided for @auditLog.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get auditLog;

  /// No description provided for @auditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get auditLogs;

  /// No description provided for @actor.
  ///
  /// In en, this message translates to:
  /// **'Actor'**
  String get actor;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get table;

  /// No description provided for @noAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'No audit entries for this period.'**
  String get noAuditLogs;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team & roles'**
  String get team;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// No description provided for @addEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add employee'**
  String get addEmployee;

  /// No description provided for @roleName.
  ///
  /// In en, this message translates to:
  /// **'Role name'**
  String get roleName;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @assignRole.
  ///
  /// In en, this message translates to:
  /// **'Assign role'**
  String get assignRole;

  /// No description provided for @noEmployees.
  ///
  /// In en, this message translates to:
  /// **'No staff accounts yet.'**
  String get noEmployees;

  /// No description provided for @roleSaved.
  ///
  /// In en, this message translates to:
  /// **'Role saved'**
  String get roleSaved;

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get memberCount;

  /// No description provided for @importExport.
  ///
  /// In en, this message translates to:
  /// **'Import / Export'**
  String get importExport;

  /// No description provided for @importCenter.
  ///
  /// In en, this message translates to:
  /// **'Import center'**
  String get importCenter;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @importProducts.
  ///
  /// In en, this message translates to:
  /// **'Import products'**
  String get importProducts;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get chooseFile;

  /// No description provided for @downloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download template'**
  String get downloadTemplate;

  /// No description provided for @importHistory.
  ///
  /// In en, this message translates to:
  /// **'Import history'**
  String get importHistory;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @noImports.
  ///
  /// In en, this message translates to:
  /// **'No imports yet.'**
  String get noImports;

  /// No description provided for @exportStarted.
  ///
  /// In en, this message translates to:
  /// **'Export prepared'**
  String get exportStarted;

  /// No description provided for @reportsHub.
  ///
  /// In en, this message translates to:
  /// **'Reports hub'**
  String get reportsHub;

  /// No description provided for @reportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Aggregated straight from the database'**
  String get reportsSubtitle;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @groupBy.
  ///
  /// In en, this message translates to:
  /// **'Group by'**
  String get groupBy;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hour;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @salesReport.
  ///
  /// In en, this message translates to:
  /// **'Sales report'**
  String get salesReport;

  /// No description provided for @profitReport.
  ///
  /// In en, this message translates to:
  /// **'Profit report'**
  String get profitReport;

  /// No description provided for @inventoryReport.
  ///
  /// In en, this message translates to:
  /// **'Inventory report'**
  String get inventoryReport;

  /// No description provided for @purchasesReport.
  ///
  /// In en, this message translates to:
  /// **'Purchases report'**
  String get purchasesReport;

  /// No description provided for @cashReport.
  ///
  /// In en, this message translates to:
  /// **'Cash & shifts report'**
  String get cashReport;

  /// No description provided for @costingReport.
  ///
  /// In en, this message translates to:
  /// **'Costing & margin'**
  String get costingReport;

  /// No description provided for @runReport.
  ///
  /// In en, this message translates to:
  /// **'Run report'**
  String get runReport;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @totalPurchases.
  ///
  /// In en, this message translates to:
  /// **'Total purchases'**
  String get totalPurchases;

  /// No description provided for @unpaidBills.
  ///
  /// In en, this message translates to:
  /// **'Unpaid bills'**
  String get unpaidBills;

  /// No description provided for @grossSales.
  ///
  /// In en, this message translates to:
  /// **'Gross sales'**
  String get grossSales;

  /// No description provided for @netSales.
  ///
  /// In en, this message translates to:
  /// **'Net sales'**
  String get netSales;

  /// No description provided for @discounts.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get discounts;

  /// No description provided for @taxCollected.
  ///
  /// In en, this message translates to:
  /// **'Tax collected'**
  String get taxCollected;

  /// No description provided for @avgBasket.
  ///
  /// In en, this message translates to:
  /// **'Average basket'**
  String get avgBasket;

  /// No description provided for @itemsPerTxn.
  ///
  /// In en, this message translates to:
  /// **'Items per transaction'**
  String get itemsPerTxn;

  /// No description provided for @cogs.
  ///
  /// In en, this message translates to:
  /// **'Cost of goods sold'**
  String get cogs;

  /// No description provided for @refundsTotal.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get refundsTotal;

  /// No description provided for @expensesTotal.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTotal;

  /// No description provided for @operatingProfit.
  ///
  /// In en, this message translates to:
  /// **'Operating profit'**
  String get operatingProfit;

  /// No description provided for @valueAtCost.
  ///
  /// In en, this message translates to:
  /// **'Value at cost'**
  String get valueAtCost;

  /// No description provided for @valueAtRetail.
  ///
  /// In en, this message translates to:
  /// **'Value at retail'**
  String get valueAtRetail;

  /// No description provided for @marginValue.
  ///
  /// In en, this message translates to:
  /// **'Potential margin'**
  String get marginValue;

  /// No description provided for @lowStockCount.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStockCount;

  /// No description provided for @outOfStockCount.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStockCount;

  /// No description provided for @deadStock.
  ///
  /// In en, this message translates to:
  /// **'Dead stock'**
  String get deadStock;

  /// No description provided for @expiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get expiringSoon;

  /// No description provided for @lastSold.
  ///
  /// In en, this message translates to:
  /// **'Last sold'**
  String get lastSold;

  /// No description provided for @neverSold.
  ///
  /// In en, this message translates to:
  /// **'Never sold'**
  String get neverSold;

  /// No description provided for @bucket0_30.
  ///
  /// In en, this message translates to:
  /// **'0–30 days'**
  String get bucket0_30;

  /// No description provided for @bucket30_60.
  ///
  /// In en, this message translates to:
  /// **'31–60 days'**
  String get bucket30_60;

  /// No description provided for @bucket60_90.
  ///
  /// In en, this message translates to:
  /// **'61–90 days'**
  String get bucket60_90;

  /// No description provided for @bucket90Plus.
  ///
  /// In en, this message translates to:
  /// **'90+ days'**
  String get bucket90Plus;

  /// No description provided for @bySupplier.
  ///
  /// In en, this message translates to:
  /// **'By supplier'**
  String get bySupplier;

  /// No description provided for @byCashier.
  ///
  /// In en, this message translates to:
  /// **'By cashier'**
  String get byCashier;

  /// No description provided for @byDay.
  ///
  /// In en, this message translates to:
  /// **'By day'**
  String get byDay;

  /// No description provided for @byProduct.
  ///
  /// In en, this message translates to:
  /// **'By product'**
  String get byProduct;

  /// No description provided for @cashierName.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get cashierName;

  /// No description provided for @marginPct.
  ///
  /// In en, this message translates to:
  /// **'Margin %'**
  String get marginPct;

  /// No description provided for @potentialProfit.
  ///
  /// In en, this message translates to:
  /// **'Potential profit'**
  String get potentialProfit;

  /// No description provided for @priceHistory.
  ///
  /// In en, this message translates to:
  /// **'Price history'**
  String get priceHistory;

  /// No description provided for @oldPrice.
  ///
  /// In en, this message translates to:
  /// **'Old price'**
  String get oldPrice;

  /// No description provided for @newPrice.
  ///
  /// In en, this message translates to:
  /// **'New price'**
  String get newPrice;

  /// No description provided for @auditChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get auditChanges;

  /// No description provided for @auditBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get auditBefore;

  /// No description provided for @auditAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get auditAfter;

  /// No description provided for @auditNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No stored changes for this entry.'**
  String get auditNoChanges;

  /// No description provided for @cashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get cashier;

  /// No description provided for @trend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get trend;

  /// No description provided for @errorNoBusiness.
  ///
  /// In en, this message translates to:
  /// **'No business is linked to this account yet.'**
  String get errorNoBusiness;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get syncStatus;

  /// No description provided for @syncOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Offline sales are stored on this device and uploaded automatically when a connection is available.'**
  String get syncOfflineHint;

  /// No description provided for @syncQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting — every offline sale has been uploaded.'**
  String get syncQueueEmpty;

  /// No description provided for @syncWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get syncWaiting;

  /// No description provided for @syncBlocked.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get syncBlocked;

  /// No description provided for @syncSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncSynced;

  /// No description provided for @syncAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get syncAttempts;

  /// No description provided for @syncLastError.
  ///
  /// In en, this message translates to:
  /// **'Last error'**
  String get syncLastError;

  /// No description provided for @syncRetryAll.
  ///
  /// In en, this message translates to:
  /// **'Retry all'**
  String get syncRetryAll;

  /// No description provided for @syncSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncSyncNow;

  /// No description provided for @syncQueuedSales.
  ///
  /// In en, this message translates to:
  /// **'Queued offline sales'**
  String get syncQueuedSales;

  /// No description provided for @syncRequested.
  ///
  /// In en, this message translates to:
  /// **'Sync started — queued sales are uploading.'**
  String get syncRequested;

  /// No description provided for @branches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branches;

  /// No description provided for @addBranch.
  ///
  /// In en, this message translates to:
  /// **'Add branch'**
  String get addBranch;

  /// No description provided for @editBranch.
  ///
  /// In en, this message translates to:
  /// **'Edit branch'**
  String get editBranch;

  /// No description provided for @noBranches.
  ///
  /// In en, this message translates to:
  /// **'No branches yet.'**
  String get noBranches;

  /// No description provided for @posTerminals.
  ///
  /// In en, this message translates to:
  /// **'POS terminals'**
  String get posTerminals;

  /// No description provided for @addTerminal.
  ///
  /// In en, this message translates to:
  /// **'Add terminal'**
  String get addTerminal;

  /// No description provided for @editTerminal.
  ///
  /// In en, this message translates to:
  /// **'Edit terminal'**
  String get editTerminal;

  /// No description provided for @noTerminals.
  ///
  /// In en, this message translates to:
  /// **'No POS terminals yet.'**
  String get noTerminals;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @financials.
  ///
  /// In en, this message translates to:
  /// **'Financials'**
  String get financials;

  /// No description provided for @totalSales.
  ///
  /// In en, this message translates to:
  /// **'Total sales'**
  String get totalSales;

  /// No description provided for @totalInvoices.
  ///
  /// In en, this message translates to:
  /// **'Total invoices'**
  String get totalInvoices;

  /// No description provided for @completedSales.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedSales;

  /// No description provided for @returnedSales.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returnedSales;

  /// No description provided for @cancelledSales.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledSales;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get netProfit;

  /// No description provided for @totalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total products'**
  String get totalProducts;

  /// No description provided for @stockUnits.
  ///
  /// In en, this message translates to:
  /// **'Stock units'**
  String get stockUnits;

  /// No description provided for @expiringIn7.
  ///
  /// In en, this message translates to:
  /// **'Expiring in 7 days'**
  String get expiringIn7;

  /// No description provided for @expiringIn30.
  ///
  /// In en, this message translates to:
  /// **'Expiring in 30 days'**
  String get expiringIn30;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @salesByDay.
  ///
  /// In en, this message translates to:
  /// **'Sales by day'**
  String get salesByDay;

  /// No description provided for @salesByMonth.
  ///
  /// In en, this message translates to:
  /// **'Sales by month'**
  String get salesByMonth;

  /// No description provided for @salesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Sales by category'**
  String get salesByCategory;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get paymentMethods;

  /// No description provided for @expensesReport.
  ///
  /// In en, this message translates to:
  /// **'Expense report'**
  String get expensesReport;

  /// No description provided for @suppliersReport.
  ///
  /// In en, this message translates to:
  /// **'Supplier report'**
  String get suppliersReport;

  /// No description provided for @customersReport.
  ///
  /// In en, this message translates to:
  /// **'Customer report'**
  String get customersReport;

  /// No description provided for @productsReport.
  ///
  /// In en, this message translates to:
  /// **'Product performance'**
  String get productsReport;

  /// No description provided for @balanceDue.
  ///
  /// In en, this message translates to:
  /// **'Balance due'**
  String get balanceDue;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount paid'**
  String get amountPaid;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get entries;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @unitsSold.
  ///
  /// In en, this message translates to:
  /// **'Units sold'**
  String get unitsSold;

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategory;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @suggestedOrderQty.
  ///
  /// In en, this message translates to:
  /// **'Suggested order qty'**
  String get suggestedOrderQty;

  /// No description provided for @inviteStaff.
  ///
  /// In en, this message translates to:
  /// **'Invite staff'**
  String get inviteStaff;

  /// No description provided for @deactivateMember.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivateMember;

  /// No description provided for @activateMember.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activateMember;

  /// No description provided for @deactivateMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be able to sign in to the app. You can reactivate them later.'**
  String get deactivateMemberConfirm;

  /// No description provided for @cannotDeactivateSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot deactivate your own account.'**
  String get cannotDeactivateSelf;

  /// No description provided for @memberActivated.
  ///
  /// In en, this message translates to:
  /// **'Member activated'**
  String get memberActivated;

  /// No description provided for @memberDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Member deactivated'**
  String get memberDeactivated;

  /// No description provided for @inviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent — the account is ready to use'**
  String get inviteSent;

  /// No description provided for @reserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get reserved;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied;

  /// No description provided for @pasteCsv.
  ///
  /// In en, this message translates to:
  /// **'Paste CSV data'**
  String get pasteCsv;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @validRows.
  ///
  /// In en, this message translates to:
  /// **'Valid rows'**
  String get validRows;

  /// No description provided for @errorRows.
  ///
  /// In en, this message translates to:
  /// **'Rows with errors'**
  String get errorRows;

  /// No description provided for @importNow.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importNow;

  /// No description provided for @imported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get imported;

  /// No description provided for @noValidRows.
  ///
  /// In en, this message translates to:
  /// **'No valid rows to import.'**
  String get noValidRows;

  /// No description provided for @errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// No description provided for @rows.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get rows;

  /// No description provided for @emptyFile.
  ///
  /// In en, this message translates to:
  /// **'The file is empty.'**
  String get emptyFile;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get phoneInvalid;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @verifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify phone'**
  String get verifyPhone;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}'**
  String otpSentTo(String phone);

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'OTP code'**
  String get otpCode;

  /// No description provided for @otpRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get otpRequired;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get otpInvalid;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @otpResent.
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent.'**
  String get otpResent;

  /// No description provided for @businesses.
  ///
  /// In en, this message translates to:
  /// **'Businesses'**
  String get businesses;

  /// No description provided for @superAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super admin'**
  String get superAdmin;

  /// No description provided for @grantSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Grant super admin'**
  String get grantSuperAdmin;

  /// No description provided for @revokeSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Revoke super admin'**
  String get revokeSuperAdmin;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App language / اپنی زبان منتخب کریں'**
  String get languageSubtitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageUrdu.
  ///
  /// In en, this message translates to:
  /// **'اردو'**
  String get languageUrdu;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your store account'**
  String get signUpSubtitle;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device?'**
  String get logoutConfirm;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
