import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final _analytics = FirebaseAnalytics.instance;

  void logSignupCompleted({required String method}) {
    _analytics.logSignUp(signUpMethod: method);
  }

  // TODO: Call when couple is first linked and user arrives at /home for the first time
  void logOnboardingCompleted({String? coupleId}) {
    _analytics.logEvent(
      name: 'onboarding_completed',
      parameters: {'couple_id': ?coupleId},
    );
  }

  void logInvitationSent({String? source}) {
    _analytics.logEvent(
      name: 'invitation_sent',
      parameters: {'source': ?source},
    );
  }

  void logInvitationAccepted({String? coupleId}) {
    _analytics.logEvent(
      name: 'invitation_accepted',
      parameters: {'couple_id': ?coupleId},
    );
  }

  void logCoupleLinked({required String coupleId}) {
    _analytics.logEvent(
      name: 'couple_linked',
      parameters: {'couple_id': coupleId},
    );
  }

  void logPartnerLinkFailed({String? reason}) {
    _analytics.logEvent(
      name: 'partner_link_failed',
      parameters: {'reason': ?reason},
    );
  }

  // TODO: Call after first successful expense save in add_expense_screen.dart
  //       (check existing expense count for this coupleId before the Firestore write)
  void logFirstExpenseCreated({String? coupleId}) {
    _analytics.logEvent(
      name: 'first_expense_created',
      parameters: {'couple_id': ?coupleId},
    );
  }

  // TODO: Call after first successful initiative save in add_initiative_screen.dart
  //       (check existing pacts count for this coupleId before the Firestore write)
  void logFirstInitiativeCreated({String? coupleId}) {
    _analytics.logEvent(
      name: 'first_initiative_created',
      parameters: {'couple_id': ?coupleId},
    );
  }

  // TODO: Call after first successful to-buy item save in add_shopping_item_screen.dart
  //       (check existing shopping items count for this coupleId before the Firestore write)
  void logFirstToBuyAdded({String? coupleId}) {
    _analytics.logEvent(
      name: 'first_tobuy_added',
      parameters: {'couple_id': ?coupleId},
    );
  }

  void logInviteScreenViewed() {
    _analytics.logScreenView(screenName: 'invite_screen');
  }

  // TODO: Identify the correct empty-state widget/screen and wire this up
  void logEmptyStateSeen({required String screenName}) {
    _analytics.logEvent(
      name: 'empty_state_seen',
      parameters: {'screen_name': screenName},
    );
  }
}
