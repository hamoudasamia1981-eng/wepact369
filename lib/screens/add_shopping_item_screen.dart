import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_localizations.dart';
import '../providers/language_provider.dart';
import '../services/shopping_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_ext.dart';

class AddShoppingItemScreen extends StatefulWidget {
  const AddShoppingItemScreen({super.key});

  @override
  State<AddShoppingItemScreen> createState() =>
      _AddShoppingItemScreenState();
}

class _AddShoppingItemScreenState extends State<AddShoppingItemScreen> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isLoading = false;
  String? _coupleId;
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    _loadCoupleId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCoupleId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _currentUid = user.uid;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      if (!mounted) return;
      final partnerId = doc.data()?['partnerId'] as String?;
      if (partnerId != null) {
        final ids = [user.uid, partnerId]..sort();
        setState(() => _coupleId = ids.join('_'));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _coupleId == null || _currentUid == null) return;
    setState(() => _isLoading = true);
    // TODO: log AnalyticsService.instance.logFirstToBuyAdded(coupleId: _coupleId)
    //       only if this is the first shopping item for this couple (check count before adding)
    final error = await ShoppingService.addItem(
      name: name,
      createdByRef: _currentUid!,
      coupleRef: _coupleId!,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).saveError),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isLoading = false);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: BackButton(color: context.colorText),
        title: Text(
          l.createToBuyLabel,
          style: TextStyle(
            color: context.colorText,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [LangToggleButton(dark: false), SizedBox(width: 8)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.shoppingItemHint,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: context.colorText,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                color: context.colorText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: l.shoppingItemHint,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        l.shoppingAddButton,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
