/// French UI strings for the application
class AppStrings {
  // App title and navigation
  static const String appTitle = 'FTS';
  static const String sessions = 'Sessions';
  static const String invoices = 'Factures';
  static const String payments = 'Versements';
  static const String remainingBalance = 'Reste à payer';

  // Status and states
  static const String status = 'Statut';
  static const String open = 'Ouverte';
  static const String closed = 'Clôturée';
  static const String closedBadge = 'CLÔTURÉE';
  static const String openStatus = 'OUVERTE';

  // Actions
  static const String add = 'Ajouter';
  static const String edit = 'Modifier';
  static const String delete = 'Supprimer';
  static const String save = 'Enregistrer';
  static const String cancel = 'Annuler';
  static const String confirm = 'Confirmer';
  static const String create = 'Créer';
  static const String reopen = 'Réouvrir';

  // Session management
  static const String newSession = 'Nouvelle session';
  static const String sessionName = 'Nom de la session';
  static const String editSessionName = 'Modifier le nom de la session';
  static const String addInvoice = 'Ajouter une facture';
  static const String addPayment = 'Ajouter un versement';
  static const String addCorrection = 'Ajouter une correction';

  // Dialogs
  static const String closeSession = 'Clôturer la session';
  static const String closeSessionConfirm = 'Clôturer cette session ? L\'ajout/modification/suppression sera verrouillé jusqu\'à la réouverture protégée.';
  static const String protectedReopen = 'Réouverture protégée';
  static const String reopenSessionConfirm = 'Réouvrir la session clôturée ? Cette action est enregistrée en tant que modification protégée.';
  static const String deleteInvoice = 'Supprimer la facture';
  static const String deleteInvoiceConfirm = 'La facture, les corrections et les liens associés seront supprimés. Continuer ?';
  static const String deleteCorrection = 'Supprimer la correction';
  static const String deleteCorrectionConfirm = 'Cette action est permanente et sera enregistrée. Continuer ?';
  static const String deletePayment = 'Supprimer le versement';
  static const String deletePaymentConfirm = 'Supprimer ce versement ? Cette action est auditée et ne peut pas être annulée.';
  static const String deletePhoto = 'Supprimer la photo';
  static const String deletePhotoConfirm = 'Supprimer les métadonnées de ce pièce jointe et la référence de fichier ?';

  // Invoices
  static const String reference = 'Référence';
  static const String supplier = 'Fournisseur';
  static const String initialRmb = 'RMB initial';
  static const String correctionsTotal = 'Total corrections';
  static const String finalAmount = 'Montant final';
  static const String totalInvoices = 'Total factures';

  // Corrections
  static const String correctionAmount = 'Montant correction RMB (+/-)';
  static const String reason = 'Raison';
  static const String amountRmb = 'Montant RMB';
  static const String confirmUpdate = 'Confirmer la mise à jour';
  static const String confirmUpdateInvoice = 'Appliquer les modifications de facture et enregistrer l\'historique d\'audit ?';
  static const String confirmUpdateCorrection = 'Appliquer les modifications de correction et maintenir la piste d\'audit ?';
  static const String confirmUpdatePayment = 'Appliquer les modifications de versement et enregistrer les valeurs anciennes/nouvelles ?';

  // Payments
  static const String date = 'Date';
  static const String amountMga = 'Montant MGA';
  static const String exchangeRate = 'Taux de change';
  static const String computedRmb = 'RMB calculé';
  static const String note = 'Note';
  static const String totalPayments = 'Total versements';

  // Attachments
  static const String attachments = 'Pièces jointes';
  static const String addPhoto = 'Ajouter une photo';
  static const String photoFromCamera = 'Ajouter une photo depuis caméra';
  static const String photoFromGallery = 'Ajouter une photo depuis galerie';
  static const String noAttachments = 'Pas de pièces jointes pour le moment';
  static const String noReceipts = 'Aucun reçu attaché pour le moment';

  // Backup & Restore
  static const String backupRestoreTitle = 'Sauvegarde et restauration';
  static const String exportBackupTitle = 'Exporter les données';
  static const String exportBackupDescription = 'Créer une sauvegarde complète de la base de données et des pièces jointes';
  static const String importBackupTitle = 'Restaurer les données';
  static const String importBackupDescription = 'Restaurer une sauvegarde précédente (remplace les données actuelles)';
  static const String exportData = 'Exporter les données';
  static const String importRestoreData = 'Importer / Restaurer les données';
  static const String confirmRestore = 'Restaurer la sauvegarde ?';
  static const String confirmRestoreTitle = 'Confirmer la restauration';
  static const String confirmRestoreMsg = 'Cela remplacera les données locales actuelles.';
  static const String confirmRestoreMessage = 'Cela remplacera les données locales actuelles.';
  static const String backupExportSuccess = 'Sauvegarde exportée avec succès: ';
  static const String exportSuccess = 'Sauvegarde exportée avec succès: ';
  static const String backupExportError = 'L\'exportation a échoué: ';
  static const String exportError = 'L\'exportation a échoué';
  static const String exportButton = 'Exporter';
  static const String importButton = 'Restaurer';
  static const String restoreButton = 'Restaurer';
  static const String cancelButton = 'Annuler';
  static const String restoreSuccess = 'La restauration est terminée avec succès. Les données ont été rechargeées.';
  static const String restoreError = 'La restauration a échouée';
  static const String infoTitle = 'Informations';
  static const String backupInfo = 'Les sauvegardes incluent toutes les sessions, factures, versements, corrections et pièces jointes. Sauvegardez régulièrement vos données.';


  // PDF & Export
  static const String pdfTitle = 'Rapport de session d\'achat';
  static const String generatePdf = 'Générer PDF';
  static const String printPdf = 'Imprimer PDF';

  // Audit
  static const String auditHistory = 'Historique d\'audit';
  static const String noAuditRecords = 'Aucun enregistrement d\'audit pour cette session.';
  static const String auditActionCreate = 'Nouvel enregistrement créé';
  static const String auditActionDelete = 'Enregistrement supprimé définitivement';
  static const String auditActionRestore = 'Données restaurées à partir de la sauvegarde';
  static const String auditActionProtectedEdit = 'Opération protégée (réouverture de session/modification de nom)';
  static const String auditNoChanges = 'Aucune modification de champ enregistrée';

  // UI strings for dialogs and actions
  static const String optional = 'optionnel';
  static const String openEdit = 'Ouvrir / Modifier';
  static const String deleteInvoiceConfirmMsg = 'Supprimer cette facture de la liste de session ?';
  static const String deletePaymentConfirmMsg = 'Supprimer ce versement de la liste de session ?';
  static const String selectPhotoSource = 'Sélectionner une source';

  // Validation errors
  static const String fieldRequired = 'Ce champ est obligatoire';
  static const String invalidAmount = 'Entrez un montant valide (format numérique)';
  static const String amountMustBePositive = 'Le montant doit être supérieur à 0';
  static const String invalidExchangeRate = 'Entrez un taux de change valide (format numérique)';
  static const String exchangeRateMustBePositive = 'Le taux de change doit être supérieur à 0';
  static const String invalidReference = 'La référence doit faire au moins 2 caractères';
  static const String invalidSessionName = 'Le nom de la session doit faire au moins 2 caractères';
  static const String invalidReason = 'La raison doit faire au moins 2 caractères';
  static const String amountCannotBeZero = 'Le montant ne peut pas être 0';

  // Summary labels
  static const String summary = 'Résumé';
  static const String created = 'Créée';
  static const String printed = 'Imprimé';

  // Loading and empty states
  static const String loading = 'Chargement...';
  static const String noData = 'Aucune donnée';
  static const String error = 'Erreur';

  // Tooltips
  static const String cannotEditClosedSession = 'Impossible de modifier une session clôturée';
  static const String closeSessionTooltip = 'Clôturer la session';
  static const String reopenSessionTooltip = 'Réouvrir la session';
  static const String editSessionTooltip = 'Modifier le nom de la session';
  static const String deletePhotoTooltip = 'Supprimer la photo';
  static const String receiptTooltip = 'Supprimer le reçu';
}
