enum ExpenseSource {
  manual,
  locationPrompt,
  shortcut,
  import,
  futureTransaction,
}

enum SyncStatus { pending, synced, conflict }

enum PlaceType {
  home,
  work,
  food,
  grocery,
  fuel,
  shopping,
  entertainment,
  health,
  bank,
  atm,
  gym,
  travel,
  unknown,
  other,
}

enum OpportunityStatus {
  pending,
  expenseAdded,
  nothingSpent,
  dismissed,
  expired,
}

enum LedgerDirection { owedToUser, owedByUser }

enum LedgerType { borrowed, lent, repayment, settlement, adjustment }

enum PaymentMethod {
  upi,
  cash,
  creditCard,
  debitCard,
  bankTransfer,
  other,
  notSpecified,
}

enum PromptStyle { frequent, smart, minimal, manualOnly }

enum LocationState {
  home,
  moving,
  arriving,
  atPlace,
  staying,
  leaving,
  travelingHome,
  unknown,
}

enum AuthProviderType { apple, google, email, local }

extension PlaceTypeX on PlaceType {
  String get label => switch (this) {
        PlaceType.home => 'Home',
        PlaceType.work => 'Office',
        PlaceType.food => 'Food',
        PlaceType.grocery => 'Grocery',
        PlaceType.fuel => 'Fuel',
        PlaceType.shopping => 'Shopping',
        PlaceType.entertainment => 'Entertainment',
        PlaceType.health => 'Health',
        PlaceType.bank => 'Bank',
        PlaceType.atm => 'ATM',
        PlaceType.gym => 'Gym',
        PlaceType.travel => 'Travel',
        PlaceType.unknown => 'Unknown',
        PlaceType.other => 'Other',
      };

  bool get isCommercial => const {
        PlaceType.food,
        PlaceType.grocery,
        PlaceType.fuel,
        PlaceType.shopping,
        PlaceType.entertainment,
        PlaceType.health,
        PlaceType.bank,
        PlaceType.atm,
        PlaceType.gym,
      }.contains(this);
}

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.upi => 'UPI',
        PaymentMethod.cash => 'Cash',
        PaymentMethod.creditCard => 'Credit Card',
        PaymentMethod.debitCard => 'Debit Card',
        PaymentMethod.bankTransfer => 'Bank Transfer',
        PaymentMethod.other => 'Other',
        PaymentMethod.notSpecified => 'Not Specified',
      };
}

extension PromptStyleX on PromptStyle {
  String get label => switch (this) {
        PromptStyle.frequent => 'Frequent',
        PromptStyle.smart => 'Smart',
        PromptStyle.minimal => 'Minimal',
        PromptStyle.manualOnly => 'Manual Only',
      };
}

String suggestedCategoryName(PlaceType type) => switch (type) {
      PlaceType.fuel => 'Fuel',
      PlaceType.grocery => 'Grocery',
      PlaceType.food => 'Food',
      PlaceType.shopping => 'Shopping',
      PlaceType.entertainment => 'Entertainment',
      PlaceType.health => 'Health',
      PlaceType.atm => 'Other',
      PlaceType.gym => 'Other',
      PlaceType.work => 'Other',
      PlaceType.home => 'Home',
      _ => 'Other',
    };
