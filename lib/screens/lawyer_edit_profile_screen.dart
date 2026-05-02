import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/profile_image_service.dart';
import '../widgets/profile_avatar.dart';
import '../models/lawyer_model.dart';
import '../data/algeria_data.dart';

class LawyerEditProfileScreen extends StatefulWidget {
  final LawyerModel? lawyer;
  const LawyerEditProfileScreen({super.key, this.lawyer});
  @override
  State<LawyerEditProfileScreen> createState() =>
      _LawyerEditProfileScreenState();
}

class _LawyerEditProfileScreenState extends State<LawyerEditProfileScreen> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locationUrlCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(); // ✅ Contrôleur email

  // 🌟 Contrôleurs pour la localisation
  String? _selectedWilaya;
  String? _selectedDaira;
  String? _selectedCommune;
  List<String> _dairas = [];
  List<String> _communes = [];

  bool _loading = true;
  bool _saving = false;
  String _error = '';
  String? _lawyerUid;
  String? _profileImageBase64;
  bool _imageChanged = false;

  final List<String> _allSpecialities = [
    'Droit familial',
    'Droit pénal',
    'Droit commercial',
    'Droit civil',
    'Droit immobilier',
    'Droit administratif',
    'Droit du travail',
    'Droit des sociétés',
    'Droit fiscal',
  ];
  final List<String> _selected = [];

  static const _navy = Color(0xFF0D1B2A);
  static const _navyLight = Color(0xFF1B2D42);
  static const _navyCard = Color(0xFF162233);
  static const _gold = Color(0xFFC9A84C);
  static const _textPrimary = Color(0xFFF0EDE8);
  static const _textSecondary = Color(0xFF8A9BB0);

  @override
  void initState() {
    super.initState();
    if (widget.lawyer != null) {
      _initFromModel(widget.lawyer!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.lawyer == null && _loading) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is LawyerModel) {
        _initFromModel(args);
      } else {
        _fetchFromFirestore();
      }
    }
  }

  void _initFromModel(LawyerModel l) {
    _lawyerUid = l.uid;
    _nameCtrl.text = l.name;
    _emailCtrl.text = l.email; // ✅ Chargement de l'email
    _phoneCtrl.text = l.phone ?? '';
    _expCtrl.text = l.experience?.toString() ?? '';
    _bioCtrl.text = l.bio ?? '';
    _locationUrlCtrl.text = l.locationUrl ?? '';
    _profileImageBase64 = l.profileImageBase64;

    // 🌟 Charger la localisation existante
    _selectedWilaya = l.wilaya;
    _selectedDaira = l.daira;
    _selectedCommune = l.commune;

    if (_selectedWilaya != null) {
      _dairas = AlgeriaData.wilayaDairas[_selectedWilaya] ?? [];
    }
    if (_selectedDaira != null) {
      _communes = AlgeriaData.dairaCommunes[_selectedDaira] ?? [];
    }

    _selected.clear();
    if (l.speciality.isNotEmpty) {
      _selected.addAll(l.speciality.split(', ').where((s) => s.isNotEmpty));
    }
    setState(() => _loading = false);
  }

  Future<void> _fetchFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final profile = await _auth.getLawyerProfile(uid);
    if (profile != null && mounted)
      _initFromModel(profile);
    else if (mounted) setState(() => _loading = false);
  }

  // 🌟 Vérifier si l'email existe déjà
  Future<bool> _isEmailAlreadyUsed(String email, String currentUid) async {
    final query = await FirebaseFirestore.instance
        .collection('lawyers')
        .where('email', isEqualTo: email)
        .get();
    return query.docs.any((doc) => doc.id != currentUid);
  }

  // 🌟 Mise à jour des Daïras selon la Wilaya
  void _updateDairas(String? wilaya) {
    if (wilaya != null) {
      setState(() {
        _selectedWilaya = wilaya;
        _selectedDaira = null;
        _selectedCommune = null;
        _dairas = AlgeriaData.wilayaDairas[wilaya] ?? [];
        _communes = [];
      });
    }
  }

  // 🌟 Mise à jour des Communes selon la Daïra
  void _updateCommunes(String? daira) {
    if (daira != null) {
      setState(() {
        _selectedDaira = daira;
        _selectedCommune = null;
        _communes = AlgeriaData.dairaCommunes[daira] ?? [];
      });
    }
  }

  // 🌟 Widget pour les dropdowns personnalisés
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required bool required,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (required)
              const Text(' *', style: TextStyle(color: _gold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _navyLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _textSecondary.withOpacity(0.2)),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            hint: Text(
              hint,
              style: TextStyle(
                color: _textSecondary.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            icon:
                Icon(Icons.keyboard_arrow_down_rounded, color: _textSecondary),
            dropdownColor: _navyLight,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: items.isEmpty
                ? []
                : items.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
            onChanged: items.isEmpty ? null : onChanged,
            validator: required
                ? (value) =>
                    value == null ? 'Veuillez choisir une $label' : null
                : null,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // ✅ Dispose de tous les contrôleurs
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _expCtrl.dispose();
    _bioCtrl.dispose();
    _locationUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _changeProfileImage() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _navyCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Photo de profil',
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _photoOption(
              icon: Icons.photo_library_rounded,
              label: 'Choisir depuis la galerie',
              color: _gold,
              onTap: () => Navigator.pop(ctx, 'pick'),
            ),
            if (_profileImageBase64 != null) ...[
              const SizedBox(height: 10),
              _photoOption(
                icon: Icons.delete_outline_rounded,
                label: 'Supprimer la photo',
                color: const Color(0xFFEF5350),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            ],
            const SizedBox(height: 10),
            _photoOption(
              icon: Icons.close_rounded,
              label: 'Annuler',
              color: _textSecondary,
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );

    if (action == null) return;

    if (action == 'pick') {
      final base64 = await ProfileImageService.pickAndCompressImage(context);
      if (base64 != null && mounted) {
        setState(() {
          _profileImageBase64 = base64;
          _imageChanged = true;
        });
      }
    } else if (action == 'remove') {
      setState(() {
        _profileImageBase64 = null;
        _imageChanged = true;
      });
    }
  }

  Widget _photoOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selected.isEmpty) {
      setState(() => _error = 'Sélectionnez au moins une spécialité');
      return;
    }

    final newEmail = _emailCtrl.text.trim();
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = _lawyerUid ?? currentUser?.uid ?? '';

    // ✅ Vérifier si l'email a changé
    final emailChanged = currentUser != null && currentUser.email != newEmail;

    setState(() {
      _saving = true;
      _error = '';
    });

    try {
      // ✅ Si l'email a changé, vérifier qu'il n'est pas déjà utilisé
      if (emailChanged) {
        final emailExists = await _isEmailAlreadyUsed(newEmail, uid);
        if (emailExists) {
          setState(() {
            _error = 'Cet email est déjà utilisé par un autre compte';
            _saving = false;
          });
          return;
        }

        // ✅ Envoyer le lien de vérification
        try {
          await currentUser?.verifyBeforeUpdateEmail(newEmail);
          await currentUser?.reload();
          _error =
              '📧 Un lien de vérification a été envoyé à votre nouvelle adresse email.\nVeuillez vérifier votre boîte de réception et cliquer sur le lien pour confirmer le changement.';
          if (mounted) setState(() => _saving = false);
          return;
        } catch (e) {
          setState(() => _error = 'Erreur mise à jour email: $e');
          if (mounted) setState(() => _saving = false);
          return;
        }
      }

      // ✅ Préparer les mises à jour
      final updates = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'email': newEmail,
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'experience': int.tryParse(_expCtrl.text),
        'speciality': _selected.join(', '),
        'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'locationUrl': _locationUrlCtrl.text.trim().isEmpty
            ? null
            : _locationUrlCtrl.text.trim(),
        'wilaya': _selectedWilaya,
        'daira': _selectedDaira,
        'commune': _selectedCommune,
      };

      // ✅ Gestion de la photo
      if (_imageChanged) {
        if (_profileImageBase64 != null) {
          updates['profileImageBase64'] = _profileImageBase64;
        } else {
          await ProfileImageService.removeProfileImage(uid, isLawyer: true);
        }
      }

      await _auth.updateLawyerProfile(uid, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Profil mis à jour !'),
            backgroundColor: Color(0xFF2E7D32)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _error = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _navy,
        body: Center(child: CircularProgressIndicator(color: _gold)),
      );
    }
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navyLight,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _navyCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x26C9A84C)),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: _textSecondary, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Modifier le profil',
            style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x1AC9A84C),
              border: Border.all(color: const Color(0x33C9A84C)),
            ),
            child: const Icon(Icons.balance_rounded, color: _gold, size: 16),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: _changeProfileImage,
                child: ProfileAvatar(
                  imageBase64: _profileImageBase64,
                  name: _nameCtrl.text,
                  size: 100,
                  borderColor: _gold,
                  borderWidth: 2.5,
                  backgroundColor: _navyLight,
                  badge: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _gold,
                      shape: BoxShape.circle,
                      border: Border.all(color: _navy, width: 2.5),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: _navy, size: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _changeProfileImage,
                child: Text(
                  _profileImageBase64 != null
                      ? 'Changer la photo'
                      : 'Ajouter une photo (optionnel)',
                  style: const TextStyle(
                      color: _gold, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('Informations personnelles'),
            const SizedBox(height: 12),
            _card(children: [
              _field(
                  label: 'Nom complet *',
                  ctrl: _nameCtrl,
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null),
              const SizedBox(height: 14),
              _field(
                  label: 'Adresse email *',
                  ctrl: _emailCtrl,
                  icon: Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Email requis' : null),
              const SizedBox(height: 14),
              _field(
                  label: 'Téléphone',
                  ctrl: _phoneCtrl,
                  icon: Icons.phone_outlined,
                  keyboard: TextInputType.phone),
            ]),
            const SizedBox(height: 24),
            _sectionLabel('Localisation du cabinet'),
            const SizedBox(height: 12),
            _card(children: [
              // Wilaya
              _buildDropdownField(
                label: 'Wilaya',
                value: _selectedWilaya,
                items: AlgeriaData.wilayaDairas.keys.toList(),
                hint: 'Sélectionnez votre wilaya',
                icon: Icons.location_city,
                required: false,
                onChanged: _updateDairas,
              ),
              const SizedBox(height: 16),

              // Daïra
              _buildDropdownField(
                label: 'Daïra',
                value: _selectedDaira,
                items: _dairas,
                hint: _selectedWilaya == null
                    ? 'Choisissez d\'abord une wilaya'
                    : 'Sélectionnez votre daïra (optionnel)',
                icon: Icons.location_on_outlined,
                required: false,
                onChanged: _updateCommunes,
              ),
              const SizedBox(height: 16),

              // Commune
              _buildDropdownField(
                label: 'Commune',
                value: _selectedCommune,
                items: _communes,
                hint: _selectedDaira == null
                    ? 'Choisissez d\'abord une daïra'
                    : 'Sélectionnez votre commune (optionnel)',
                icon: Icons.place_outlined,
                required: false,
                onChanged: (value) {
                  setState(() {
                    _selectedCommune = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Lien Google Maps
              _field(
                  label: 'Lien Google Maps (optionnel)',
                  ctrl: _locationUrlCtrl,
                  icon: Icons.map_outlined),
            ]),
            const SizedBox(height: 24),
            _sectionLabel('Profil professionnel'),
            const SizedBox(height: 12),
            _card(children: [
              _field(
                  label: "Années d'expérience",
                  ctrl: _expCtrl,
                  icon: Icons.work_outline_rounded,
                  keyboard: TextInputType.number),
              const SizedBox(height: 16),
              Text('Spécialités *',
                  style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              _specialitiesGrid(),
            ]),
            const SizedBox(height: 24),
            _sectionLabel('Bio / Description'),
            const SizedBox(height: 12),
            _card(children: [
              _field(
                  label: 'Bio',
                  ctrl: _bioCtrl,
                  icon: Icons.description_outlined,
                  maxLines: 5),
            ]),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0x607B1F1F),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x60C62828)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFEF9A9A), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_error,
                          style: const TextStyle(
                              color: Color(0xFFEF9A9A), fontSize: 13))),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textSecondary,
                  side: BorderSide(color: _textSecondary.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('ANNULER'),
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _navy,
                  disabledBackgroundColor: _gold.withOpacity(0.35),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(_navy)))
                    : const Text('ENREGISTRER',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, letterSpacing: 1)),
              )),
            ]),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String t) => Row(children: [
        Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
                color: _gold, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 10),
        Text(t.toUpperCase(),
            style: const TextStyle(
                color: _textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
      ]);

  Widget _card({required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: _textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboard,
          style: const TextStyle(color: _textPrimary, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _textSecondary, size: 20),
            filled: true,
            fillColor: _navyLight,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _textSecondary.withOpacity(0.2))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _gold, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFEF5350))),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFEF5350))),
            errorStyle: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 12),
          ),
          validator: validator,
        ),
      ]);

  Widget _specialitiesGrid() {
    final maxed = _selected.length >= 3;
    return Column(children: [
      Align(
          alignment: Alignment.centerRight,
          child: Text('${_selected.length}/3',
              style: TextStyle(
                  color: maxed ? _gold : _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600))),
      const SizedBox(height: 8),
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allSpecialities.map((s) {
            final sel = _selected.contains(s);
            final dis = !sel && maxed;
            return GestureDetector(
              onTap: dis
                  ? null
                  : () => setState(
                      () => sel ? _selected.remove(s) : _selected.add(s)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? const Color(0x33C9A84C) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel
                        ? _gold
                        : dis
                            ? const Color(0x0F8A9BB0)
                            : const Color(0x228A9BB0),
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (sel)
                    const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child:
                            Icon(Icons.check_rounded, size: 14, color: _gold)),
                  Text(s,
                      style: TextStyle(
                        color: sel
                            ? _gold
                            : dis
                                ? const Color(0x448A9BB0)
                                : _textSecondary,
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                      )),
                ]),
              ),
            );
          }).toList()),
    ]);
  }
}
