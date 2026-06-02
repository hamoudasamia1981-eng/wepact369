import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';

class AppLocalizations {
  final String languageCode;
  bool get isFr => languageCode == 'fr';

  const AppLocalizations(this.languageCode);

  static AppLocalizations of(BuildContext context) =>
      context.watch<LanguageProvider>().l10n;

  // ── DATES ──────────────────────────────────────────────────
  List<String> get monthsFull => isFr
      ? ['janvier','février','mars','avril','mai','juin',
         'juillet','août','septembre','octobre','novembre','décembre']
      : ['January','February','March','April','May','June',
         'July','August','September','October','November','December'];

  List<String> get monthsShort => isFr
      ? ['jan','fév','mar','avr','mai','juin','juil','août','sep','oct','nov','déc']
      : ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  List<String> get dayHeaders => isFr
      ? ['D','L','M','M','J','V','S']
      : ['S','M','T','W','T','F','S'];

  List<String> get daysFull => isFr
      ? ['Dimanche','Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi']
      : ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];

  // ── COMMON ─────────────────────────────────────────────────
  String get cancel => isFr ? 'Annuler' : 'Cancel';
  String get confirm => isFr ? 'Confirmer' : 'Confirm';
  String get save => isFr ? 'Enregistrer' : 'Save';
  String get delete => isFr ? 'Supprimer' : 'Delete';
  String get seeAll => isFr ? 'Voir tout' : 'See all';
  String get comingSoon => isFr ? 'Bientôt disponible' : 'Coming soon';
  String get fieldRequired => isFr ? 'Champ requis' : 'Required';
  String get saveError => isFr ? "Erreur lors de l'enregistrement." : 'Error saving.';
  String get chooseDate => isFr ? 'Choisir une date' : 'Choose a date';
  String get youLabel => isFr ? 'Vous' : 'You';
  String get partnerLabel => isFr ? 'Partenaire' : 'Partner';
  String get meLabel => isFr ? 'Moi' : 'Me';
  String get enterTitle => isFr ? 'Veuillez saisir un titre.' : 'Please enter a title.';
  String get linkPartnerFirst =>
      isFr ? "Liez d'abord votre compte à un partenaire."
           : 'Link your account to a partner first.';
  String get connectPartnerMsg =>
      isFr ? 'Connectez-vous à votre partenaire pour commencer'
           : 'Connect with your partner to get started';

  // ── AUTH ERRORS ─────────────────────────────────────────────
  String authError(String code) => isFr
      ? switch (code) {
          'user-not-found' => 'Aucun compte trouvé avec cet email.',
          'wrong-password' ||
          'invalid-credential' => 'Email ou mot de passe incorrect.',
          'email-already-in-use' => 'Un compte existe déjà avec cet email.',
          'invalid-email' => 'Adresse email invalide.',
          'weak-password' => 'Mot de passe trop faible.',
          'user-disabled' => 'Ce compte a été désactivé.',
          'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
          'network-request-failed' =>
            'Erreur réseau. Vérifiez votre connexion.',
          _ => 'Une erreur est survenue. Veuillez réessayer.',
        }
      : switch (code) {
          'user-not-found' => 'No account found with this email.',
          'wrong-password' ||
          'invalid-credential' => 'Incorrect email or password.',
          'email-already-in-use' =>
            'An account already exists with this email.',
          'invalid-email' => 'Invalid email address.',
          'weak-password' => 'Password is too weak.',
          'user-disabled' => 'This account has been disabled.',
          'too-many-requests' => 'Too many attempts. Try again later.',
          'network-request-failed' => 'Network error. Check your connection.',
          _ => 'An error occurred. Please try again.',
        };

  // ── LOGIN ───────────────────────────────────────────────────
  String get loginTitle => isFr ? 'Bon retour 👋' : 'Welcome back 👋';
  String get loginSubtitle =>
      isFr ? 'Content de vous revoir' : 'Good to see you';
  String get emailLabel => 'Email';
  String get passwordLabel => isFr ? 'Mot de passe' : 'Password';
  String get forgotPasswordQ =>
      isFr ? 'Mot de passe oublié ?' : 'Forgot password?';
  String get signInButton => isFr ? 'Se connecter' : 'Sign in';
  String get orContinueWith =>
      isFr ? 'ou continuer avec' : 'or continue with';
  String get continueWithGoogle =>
      isFr ? 'Continuer avec Google' : 'Continue with Google';
  String get noAccountYet =>
      isFr ? 'Pas encore de compte ? ' : 'No account yet? ';
  String get signUpLink => isFr ? "S'inscrire" : 'Sign up';
  String get fillAllFields =>
      isFr ? 'Veuillez remplir tous les champs.' : 'Please fill in all fields.';
  String get googleCancelled =>
      isFr ? 'Connexion Google annulée.' : 'Google sign-in cancelled.';

  // ── SIGNUP ──────────────────────────────────────────────────
  String get signupTitle => isFr ? 'Créer un compte' : 'Create account';
  String get firstNameLabel => isFr ? 'Prénom' : 'First name';
  String get lastNameLabel => isFr ? 'Nom' : 'Last name';
  String get genderLabel => isFr ? 'Genre' : 'Gender';
  String get maleLabel => isFr ? 'Homme' : 'Male';
  String get femaleLabel => isFr ? 'Femme' : 'Female';
  String get confirmPasswordLabel =>
      isFr ? 'Confirmer le mot de passe' : 'Confirm password';
  String get createAccountButton =>
      isFr ? 'Créer mon compte' : 'Create my account';
  String get alreadyAccount =>
      isFr ? 'Déjà un compte ? ' : 'Already have an account? ';
  String get signInLink => isFr ? 'Se connecter' : 'Sign in';
  String get acceptTermsPrefix => isFr ? "J'accepte les " : 'I accept the ';
  String get termsLink =>
      isFr ? "Conditions d'utilisation" : 'Terms of use';
  String get andThe => isFr ? ' et la ' : ' and the ';
  String get privacyLink =>
      isFr ? 'Politique de confidentialité' : 'Privacy policy';
  String get acceptTermsError =>
      isFr ? 'Veuillez accepter les conditions' : 'Please accept the terms';
  String get passwordMin =>
      isFr ? 'Minimum 6 caractères' : 'At least 6 characters';
  String get passwordsMismatch =>
      isFr ? 'Les mots de passe ne correspondent pas'
           : 'Passwords do not match';
  String get signupError =>
      isFr ? 'Erreur lors de la création du compte. Veuillez réessayer.'
           : 'Error creating account. Please try again.';

  // ── FORGOT PASSWORD ─────────────────────────────────────────
  String get forgotPasswordTitle =>
      isFr ? 'Mot de passe oublié' : 'Forgot password';
  String get forgotPasswordHeading =>
      isFr ? 'Mot de passe oublié ?' : 'Forgot your password?';
  String get forgotPasswordBody => isFr
      ? 'Entrez votre email et nous vous enverrons un lien de réinitialisation.'
      : "Enter your email and we'll send you a reset link.";
  String get sendLink => isFr ? 'Envoyer le lien' : 'Send reset link';
  String get checkInbox =>
      isFr ? 'Vérifiez votre messagerie' : 'Check your inbox';
  String get resetSentTo => isFr
      ? 'Un lien de réinitialisation a été envoyé à'
      : 'A reset link was sent to';
  String get backToLogin =>
      isFr ? 'Retour à la connexion' : 'Back to login';
  String get enterEmail =>
      isFr ? 'Entrez votre email' : 'Enter your email';
  String get invalidEmail => isFr ? 'Email invalide' : 'Invalid email';

  // ── INVITE PARTNER ──────────────────────────────────────────
  String get inviteTitle =>
      isFr ? 'Inviter mon partenaire' : 'Invite my partner';
  String get inviteSubtitle => isFr
      ? 'Liez vos comptes pour commencer ensemble.'
      : 'Link your accounts to start together.';
  String get partnerEmailLabel =>
      isFr ? 'Email de votre partenaire' : "Partner's email";
  String get inviteButton =>
      isFr ? 'Inviter mon partenaire' : 'Invite my partner';
  String get cancelInviteButton =>
      isFr ? "Annuler l'invitation" : 'Cancel invitation';
  String get inviteSent =>
      isFr ? 'Invitation envoyée avec succès !' : 'Invitation sent!';
  String get invitePendingTitle =>
      isFr ? 'Invitation envoyée' : 'Invitation sent';
  String get invitePendingSubtitle => isFr
      ? 'En attente de la réponse de votre partenaire...'
      : 'Waiting for your partner to accept...';
  String get enterPartnerEmail =>
      isFr ? 'Veuillez saisir un email.' : 'Please enter an email.';

  // ── HOME ────────────────────────────────────────────────────
  String greeting(int hour) {
    if (isFr) {
      if (hour < 12) return 'Bonjour,';
      if (hour < 18) return 'Bon après-midi,';
      return 'Bonsoir,';
    } else {
      if (hour < 12) return 'Good morning,';
      if (hour < 18) return 'Good afternoon,';
      return 'Good evening,';
    }
  }

  String get pendingResponseInline =>
      isFr ? '❤️ Une décision attend votre réponse'
           : '❤️ A decision awaits your response';
  String pendingBannerText(int n) => isFr
      ? '$n pacte${n != 1 ? 's' : ''} en attente de votre réponse'
      : '$n pact${n != 1 ? 's' : ''} awaiting your response';
  String get proposedPacts => isFr ? 'Pacts proposés' : 'Proposed pacts';
  String get acceptedPacts => isFr ? 'Pacts acceptés' : 'Accepted pacts';
  String get thisMonth => isFr ? 'Ce mois-ci' : 'This month';
  String get recentActivity => isFr ? 'Activité récente' : 'Recent activity';
  String get noActivity =>
      isFr ? 'Aucune activité pour le moment' : 'No activity yet';
  String proposedBy(String name) =>
      isFr ? 'Proposé par $name' : 'Proposed by $name';
  String get invitePartnerButton =>
      isFr ? 'Inviter mon partenaire' : 'Invite my partner';

  // ── EXPENSES ────────────────────────────────────────────────
  String get expensesTitle => isFr ? 'Dépenses' : 'Expenses';
  String get todayFilter => isFr ? "Aujourd'hui" : 'Today';
  String get weekFilter => isFr ? 'Semaine' : 'Week';
  String get monthFilter => isFr ? 'Mois' : 'Month';
  String get yearFilter => isFr ? 'Année' : 'Year';
  List<String> get periodFilters =>
      [todayFilter, weekFilter, monthFilter, yearFilter];
  String get addPactButton =>
      isFr ? '+ Ajouter un pacte' : '+ Add a pact';
  String get togetherBanner =>
      isFr ? '💜 Profitez de votre temps ensemble' : '💜 Enjoy your time together';
  String get addExpenseButton =>
      isFr ? '+ Ajouter une dépense' : '+ Add an expense';
  String get noExpenses =>
      isFr ? 'Aucune dépense pour cette période' : 'No expenses for this period';
  String get connectForExpenses => isFr
      ? 'Connectez-vous à un partenaire pour voir les dépenses.'
      : 'Connect with a partner to see expenses.';
  String get ensembleLabel => isFr ? 'ensemble' : 'together';
  String get deleteExpenseTitle =>
      isFr ? 'Supprimer la dépense' : 'Delete expense';
  String get confirmDeleteMsg =>
      isFr ? 'Confirmer la suppression ?' : 'Confirm deletion?';
  String get newExpenseTitle => isFr ? 'Nouvelle dépense' : 'New expense';
  String get titleFieldLabel => isFr ? 'Titre' : 'Title';
  String get titleHint =>
      isFr ? 'ex. Courses du samedi' : 'e.g. Saturday shopping';
  String get amountLabel => isFr ? 'Montant' : 'Amount';
  String get categoryLabel => isFr ? 'Catégorie' : 'Category';
  String get dateLabel => isFr ? 'Date' : 'Date';
  String get saveExpenseButton =>
      isFr ? 'Enregistrer la dépense' : 'Save expense';
  String get validAmount => isFr
      ? 'Veuillez saisir un montant valide.'
      : 'Please enter a valid amount.';

  String expenseCategoryLabel(String key) =>
      isFr ? key : const {
        'Alimentation': 'Food',
        'Loyer': 'Rent',
        'Restaurant': 'Restaurant',
        'Transport': 'Transport',
        'Enfants': 'Kids',
        'Maison': 'Home',
        'Loisirs': 'Leisure',
        'Santé': 'Health',
        'Autre': 'Other',
      }[key] ?? key;

  // ── PACTS ────────────────────────────────────────────────────
  String get pactsTitle => isFr ? 'Pactes' : 'Pacts';
  String get toDoTab => isFr ? 'À faire' : 'To do';
  String get pendingTab => isFr ? 'En attente' : 'Pending';
  String get declinedTab => isFr ? 'Refusé' : 'Declined';
  String get acceptedBadge => isFr ? 'Accepté' : 'Accepted';
  String get declinedBadge => isFr ? 'Refusé' : 'Declined';
  String get pendingBadge => isFr ? 'En attente' : 'Pending';
  String get expenseBadge => isFr ? 'Dépense' : 'Expense';
  String get noAcceptedPacts =>
      isFr ? 'Aucun pact accepté' : 'No accepted pacts';
  String get noPendingPacts =>
      isFr ? 'Aucune proposition en attente' : 'No pending proposals';
  String get noDeclinedPacts =>
      isFr ? 'Aucun pact refusé' : 'No declined pacts';
  String get acceptButton => isFr ? 'Accepter' : 'Accept';
  String get declineButton => isFr ? 'Refuser' : 'Decline';

  // Add Task
  String get newTaskTitle => isFr ? 'Nouvelle tâche' : 'New task';
  String get taskTitleLabel => isFr ? 'Titre de la tâche' : 'Task title';
  String get taskHint =>
      isFr ? 'ex. Réserver restaurant' : 'e.g. Book restaurant';
  String get descriptionLabel =>
      isFr ? 'Description (optionnel)' : 'Description (optional)';
  String get descriptionHint =>
      isFr ? 'Ajoutez des détails...' : 'Add details...';
  String get deadlineLabel => isFr ? 'Date limite' : 'Deadline';
  String get proposeTaskButton =>
      isFr ? 'Proposer la tâche' : 'Propose task';

  String taskCategoryLabel(String key) => isFr
      ? const {
          'Maison': 'Maison',
          'Enfants': 'Enfants',
          'Autre': 'Autres',
        }[key] ?? key
      : const {
          'Maison': 'Home',
          'Enfants': 'Kids',
          'Autre': 'Other',
        }[key] ?? key;

  // Add Initiative
  String get newInitiativeTitle =>
      isFr ? 'Nouvelle initiative' : 'New initiative';
  String get initiativeTitleLabel =>
      isFr ? "Titre de l'initiative" : 'Initiative title';
  String get initiativeHint =>
      isFr ? 'ex. Dîner romantique' : 'e.g. Romantic dinner';
  String get initiativeDescHint =>
      isFr ? 'Décrivez votre idée...' : 'Describe your idea...';
  String get timeLabel => isFr ? 'Heure' : 'Time';
  String get locationLabel =>
      isFr ? 'Lieu (optionnel)' : 'Location (optional)';
  String get locationHint =>
      isFr ? 'ex. Restaurant Le Jardin' : 'e.g. Restaurant Le Jardin';
  String get proposeInitiativeButton =>
      isFr ? "Proposer l'initiative" : 'Propose initiative';

  String initiativeCategoryLabel(String key) =>
      isFr ? key : const {
        'Sortie': 'Outing',
        'Voyage': 'Trip',
        'Restaurant': 'Restaurant',
        'Cinéma': 'Cinema',
        'Cadeau': 'Gift',
        'Autre': 'Other',
      }[key] ?? key;

  // ── CALENDAR ────────────────────────────────────────────────
  String get calendarTitle => isFr ? 'Calendrier' : 'Calendar';
  String get noPactsDay => isFr ? 'Aucun pacte ce jour' : 'No pacts today';
  String get connectCalendar => isFr
      ? 'Connectez-vous à un partenaire pour voir le calendrier.'
      : 'Connect with a partner to see the calendar.';
  String get taskType => isFr ? 'Tâche' : 'Task';
  String get initiativeType => isFr ? 'Initiative' : 'Initiative';
  String pacteCount(int n) =>
      isFr ? '$n pacte${n != 1 ? 's' : ''}' : '$n pact${n != 1 ? 's' : ''}';

  // ── PROFILE ─────────────────────────────────────────────────
  String get partnerSection => isFr ? 'PARTENAIRE' : 'PARTNER';
  String get settingsSection => isFr ? 'PARAMÈTRES' : 'SETTINGS';
  String get settingsLabel => isFr ? 'Paramètres' : 'Settings';
  String get darkModeLabel => isFr ? 'Mode sombre' : 'Dark mode';
  String get notificationsLabel => isFr ? 'Notifications' : 'Notifications';
  String get signOutLabel => isFr ? 'Se déconnecter' : 'Sign out';
  String get signOutTitle => isFr ? 'Déconnexion' : 'Sign out';
  String get signOutConfirm => isFr
      ? 'Êtes-vous sûr de vouloir vous déconnecter ?'
      : 'Are you sure you want to sign out?';
  String connectedWith(String name) =>
      isFr ? '❤️ Connecté avec $name' : '❤️ Connected with $name';
  String togetherSince(String date) =>
      isFr ? '❤️ Ensemble depuis le $date' : '❤️ Together since $date';
  String get proposedLabel => isFr ? 'Proposés' : 'Proposed';
  String get acceptedLabel => isFr ? 'Acceptés' : 'Accepted';
  String get totalLabel => isFr ? 'Total' : 'Total';

  // ── SETTINGS ────────────────────────────────────────────────
  String get settingsTitle => isFr ? 'Paramètres' : 'Settings';
  String get currencyLabel => isFr ? 'Devise' : 'Currency';
  String get languageLabel => isFr ? 'Langue' : 'Language';
  String get nameSection => isFr ? 'NOM' : 'NAME';
  String get darkModeSection => isFr ? 'MODE SOMBRE' : 'DARK MODE';
  String get saveChanges =>
      isFr ? 'Enregistrer les modifications' : 'Save changes';
  String get nameUpdated => isFr ? 'Nom mis à jour !' : 'Name updated!';

  // ── MAIN NAVIGATION ─────────────────────────────────────────
  String get navHome => isFr ? 'Accueil' : 'Home';
  String get navExpenses => isFr ? 'Dépenses' : 'Expenses';
  String get navPacts => isFr ? 'Pactes' : 'Pacts';
  String get navCalendar => isFr ? 'Calendrier' : 'Calendar';
  String get navShopping => isFr ? 'À acheter' : 'To Buy';
  String get navProfile => isFr ? 'Profil' : 'Profile';
  String get createWhat =>
      isFr ? 'Que voulez-vous créer ?' : 'What do you want to create?';
  String get createExpenseLabel => isFr ? 'Dépense' : 'Expense';
  String get createExpenseSubtitle =>
      isFr ? 'Ajouter une dépense partagée' : 'Add a shared expense';
  String get createTaskLabel => isFr ? 'Tâche' : 'Task';
  String get createTaskSubtitle =>
      isFr ? 'À organiser ou à faire' : 'To organize or do';
  String get createInitiativeLabel => isFr ? 'Initiative' : 'Initiative';
  String get createInitiativeSubtitle =>
      isFr ? 'Une idée à partager' : 'An idea to share';
  String get createToBuyLabel => isFr ? 'À acheter' : 'To Buy';
  String get createToBuySubtitle =>
      isFr ? 'Ajouter un produit à acheter' : 'Add an item to buy';

  // ── SPLASH ──────────────────────────────────────────────────
  String get splashTagline =>
      isFr ? 'La vie à deux, sans friction.' : 'Couple life, without friction.';

  // ── SHOPPING LIST ───────────────────────────────────────────
  String get shoppingListTitle => isFr ? 'À acheter' : 'To Buy';
  String get shoppingListEmpty =>
      isFr ? 'Votre liste est vide. Ajoutez un article.'
           : 'Your list is empty. Add an item.';
  String get shoppingItemHint => isFr ? "Nom de l'article" : 'Item name';
  String get shoppingAddButton => isFr ? 'Ajouter' : 'Add';
  String get shoppingPurchasedSection => isFr ? 'Acheté' : 'Purchased';
  String get shoppingActiveSection => isFr ? 'À acheter' : 'To Buy';
  String get shoppingActivityAdded =>
      isFr ? 'Article à acheter' : 'Item to buy';
  String get shoppingActivityBought =>
      isFr ? 'Article acheté' : 'Item purchased';
  String shoppingGroupAdded(int n) => isFr
      ? '$n articles à acheter'
      : '$n items to buy';
  String shoppingGroupBought(int n) => isFr
      ? '$n articles achetés'
      : '$n items purchased';
  String shoppingBannerText(int n) => isFr
      ? '$n ${n > 1 ? 'articles' : 'article'} à acheter'
      : '$n ${n > 1 ? 'items' : 'item'} to buy';
  String get shoppingClearPurchased =>
      isFr ? 'Vider les articles achetés' : 'Clear purchased items';
  String get shoppingClearConfirmTitle =>
      isFr ? 'Vider les articles achetés ?' : 'Clear purchased items?';
  String get shoppingClearConfirmBody =>
      isFr ? 'Tous les articles achetés seront supprimés définitivement.'
           : 'All purchased items will be permanently deleted.';
  String get shoppingNoPartner =>
      isFr ? 'Liez votre compte à un partenaire pour partager la liste.'
           : 'Link your account to a partner to share the list.';
  String get shoppingAddedBy => isFr ? 'Ajouté par :' : 'Added by:';
  String get shoppingBoughtBy => isFr ? 'Acheté par :' : 'Bought by:';
}

// ── REUSABLE LANGUAGE TOGGLE BUTTON ────────────────────────────
class LangToggleButton extends StatelessWidget {
  final bool dark;
  const LangToggleButton({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LanguageProvider>();
    return GestureDetector(
      onTap: () =>
          provider.setLanguage(provider.code == 'fr' ? 'en' : 'fr'),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(
            color: dark
                ? Colors.white54
                : AppColors.textGrey.withAlpha(120),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.code == 'fr' ? '🇫🇷' : '🇬🇧',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(width: 4),
            Text(
              provider.code.toUpperCase(),
              style: TextStyle(
                color: dark ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
