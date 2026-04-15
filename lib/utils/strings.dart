class AppStrings {
  // APP
  static const String appTitle = 'FTS';

  // MENU / ONGLETS
  static const String sessions = 'Sessions';
  static const String invoices = 'Factures';
  static const String payments = 'Versements';

  // ACTIONS GÉNÉRALES
  static const String add = 'Ajouter';
  static const String edit = 'Modifier';
  static const String delete = 'Supprimer';
  static const String save = 'Enregistrer';
  static const String cancel = 'Annuler';
  static const String create = 'Créer';
  static const String reopen = 'Rouvrir';
  static const String openEdit = 'Ouvrir la modification';

  // CHAMPS
  static const String date = 'Date';
  static const String note = 'Note';
  static const String reference = 'Référence';
  static const String supplier = 'Fournisseur';
  static const String sessionName = 'Nom de la session';
  static const String optional = 'optionnel';

  // MONTANTS
  static const String amountMga = 'Montant MGA';
  static const String exchangeRate = 'Taux de change';
  static const String rmb = 'RMB';
  static const String initialRmb = 'Montant initial RMB';
  static const String correctionsTotal = 'Total corrections';
  static const String finalAmount = 'Montant final';
  static const String totalInvoices = 'Total Factures';
  static const String totalPayments = 'Total Versements';
  static const String remaining = 'Reste à payer';
  static const String remainingBalance = 'Reste à payer';

  // STATUTS
  static const String status = 'Statut';
  static const String open = 'Ouverte';
  static const String closed = 'Clôturée';
  static const String closedBadge = 'CLÔTURÉE';

  // SESSIONS
  static const String newSession = 'Nouvelle session';
  static const String editSessionName = 'Modifier le nom de la session';
  static const String closeSession = 'Clôturer la session';
  static const String closeSessionConfirm =
      'Voulez-vous vraiment clôturer cette session ?';
  static const String protectedReopen = 'Réouverture protégée';
  static const String reopenSessionConfirm =
      'Voulez-vous rouvrir cette session ?';
  static const String closeSessionTooltip = 'Clôturer la session';
  static const String reopenSessionTooltip = 'Rouvrir la session';
  static const String editSessionTooltip = 'Modifier la session';
  static const String cannotEditClosedSession =
      'Modification impossible : session clôturée';

  // FACTURES
  static const String addInvoice = 'Ajouter une facture';
  static const String deleteInvoice = 'Supprimer la facture';
  static const String deleteInvoiceConfirm =
      'Voulez-vous supprimer cette facture ?';
  static const String deleteInvoiceConfirmMsg =
      'Cette facture sera supprimée définitivement.';

  // CORRECTIONS
  static const String addCorrection = 'Ajouter une correction';

  // VERSEMENTS
  static const String addPayment = 'Ajouter un versement';
  static const String editPayment = 'Modifier le versement';
  static const String deletePayment = 'Supprimer le versement';
  static const String deletePaymentConfirmMsg =
      'Voulez-vous supprimer ce versement ?';
  static const String paymentDetail = 'Détail du versement';

  // PHOTOS / PIÈCES JOINTES
  static const String attachments = 'Pièces jointes';
  static const String noReceipts = 'Aucun reçu';
  static const String addPhoto = 'Ajouter une photo';
  static const String deletePhotoTooltip = 'Supprimer la photo';
  static const String photoFromCamera = 'Prendre une photo';
  static const String photoFromGallery = 'Choisir depuis la galerie';

  // AUDIT
  static const String auditHistory = 'Historique des modifications';
  static const String noAuditRecords = 'Aucun historique disponible';
  static const String auditNoChanges = 'Aucun changement détecté';
  static const String auditActionCreate = 'Création';
  static const String auditActionDelete = 'Suppression';
  static const String auditActionRestore = 'Restauration';
  static const String auditActionProtectedEdit = 'Modification protégée';

  // BACKUP / RESTORE
  static const String backupRestore = 'Sauvegarde / Restauration';
  static const String backupRestoreTitle = 'Sauvegarde et restauration';
  static const String backupInfo =
      'Exportez vos données pour éviter toute perte, puis restaurez-les si nécessaire.';
  static const String exportBackupTitle = 'Exporter les données';
  static const String exportBackupDescription =
      'Créer une sauvegarde complète de la base et des pièces jointes.';
  static const String importBackupTitle = 'Importer / Restaurer les données';
  static const String importBackupDescription =
      'Restaurer une sauvegarde existante.';
  static const String exportData = 'Exporter les données';
  static const String importRestoreData = 'Importer / Restaurer les données';
  static const String exportButton = 'Exporter';
  static const String importButton = 'Importer';
  static const String restoreButton = 'Restaurer';
  static const String confirmRestoreTitle = 'Confirmer la restauration';
  static const String confirmRestoreMessage =
      'La restauration remplacera les données actuelles. Continuer ?';
  static const String exportSuccess = 'Export réussi :';
  static const String exportError = 'Erreur export';
  static const String restoreSuccess = 'Restauration réussie';
  static const String restoreError = 'Erreur restauration';
  static const String cancelButton = 'Annuler';

  // DIVERS
  static const String infoTitle = 'Information';
  static const String error = 'Erreur';
  static const String noData = 'Aucune donnée';
  static const String confirmDelete = 'Confirmer la suppression ?';
}
