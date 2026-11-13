/// One part of the legal notice: a title, and its paragraphs.
class LegalNoticeSection {
  const LegalNoticeSection({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;
}

/// Content of the legal notice of FlorAccess, shared by the API and the
/// applications which sign their users in with it.
///
/// To update when one of these facts changes: publisher, host, mail service,
/// data stored by floraccess-api, retention of the accounts (cron job of
/// floraccess-api), duration of the backups (floraccess-wrapper).
abstract class LegalNoticeContent {
  static const String lastUpdate = '11 novembre 2026';
  static const String contactEmail = 'floris@florobart.fr';

  static const List<LegalNoticeSection> sections = [
    LegalNoticeSection(
      title: 'Éditeur',
      paragraphs: [
        'FlorAccess est édité par FloRobart, particulier non professionnel, '
            'qui en est aussi le directeur de la publication.',
        'Conformément à l\'article 6, III, 2 de la loi n° 2004-575 du '
            '21 juin 2004 pour la confiance dans l\'économie numérique, ses '
            'coordonnées personnelles ont été communiquées à l\'hébergeur.',
        'Contact : $contactEmail',
      ],
    ),
    LegalNoticeSection(
      title: 'Hébergeur',
      paragraphs: [
        'OVH SAS, société par actions simplifiée au capital de 50 000 000 €, '
            'immatriculée au RCS de Lille Métropole sous le numéro '
            '424 761 419 00045.',
        'Siège social : 2 rue Kellermann, 59100 Roubaix, France.',
        'Téléphone : 1007 (depuis la France).',
      ],
    ),
    LegalNoticeSection(
      title: 'Le service',
      paragraphs: [
        'FlorAccess est le service de connexion des applications de FloRobart '
            '(Econoris, Flollylist, Le Mans Roller Live) : un même compte '
            'permet de se connecter à chacune d\'elles, avec un code reçu par '
            'email.',
      ],
    ),
    LegalNoticeSection(
      title: 'Données personnelles',
      paragraphs: [
        'Responsable du traitement : FloRobart ($contactEmail).',
        'Données conservées pour chaque compte : l\'adresse email, le pseudo, '
            'l\'adresse IP de la dernière connexion, les dates de création, de '
            'connexion et de déconnexion, et l\'état de vérification de '
            'l\'adresse email. Les codes de connexion et les liens envoyés par '
            'email ne sont conservés que sous une forme chiffrée '
            'irréversible (hachée).',
        'Finalités : permettre la connexion aux applications, et protéger les '
            'comptes contre les abus (limites de requêtes, blocage des '
            'connexions). Bases légales : l\'exécution du service demandé par '
            'l\'utilisateur, et l\'intérêt légitime de sécuriser ce service '
            '(article 6.1 b et f du RGPD).',
        'Destinataires : les données ne sont ni vendues ni cédées. Elles sont '
            'hébergées chez OVH SAS, et les emails de connexion sont envoyés '
            'par le service de messagerie Gmail de Google. Les applications de '
            'FloRobart qui utilisent FlorAccess reçoivent le pseudo, l\'adresse '
            'email et l\'identifiant du compte de leurs utilisateurs.',
      ],
    ),
    LegalNoticeSection(
      title: 'Durée de conservation',
      paragraphs: [
        'Un compte dont l\'adresse email a été vérifiée est conservé jusqu\'à '
            'sa suppression, par l\'utilisateur ou sur sa demande.',
        'Un compte dont l\'adresse email n\'a jamais été vérifiée est supprimé '
            'automatiquement trois mois après sa création, lors de la '
            'suppression faite au début de chaque mois.',
        'Les journaux techniques du serveur (adresses IP, requêtes) sont '
            'effacés au fur et à mesure par une rotation automatique. Les '
            'sauvegardes de la base de données sont chiffrées, et seules les '
            '30 dernières sont conservées.',
      ],
    ),
    LegalNoticeSection(
      title: 'Vos droits',
      paragraphs: [
        'Vous pouvez accéder à vos données, les faire rectifier ou effacer, '
            'en limiter le traitement, vous y opposer, ou en demander une '
            'copie, en écrivant à $contactEmail.',
        'Si vous estimez que vos droits ne sont pas respectés, vous pouvez '
            'adresser une réclamation à la CNIL (www.cnil.fr).',
      ],
    ),
    LegalNoticeSection(
      title: 'Cookies et stockage local',
      paragraphs: [
        'FlorAccess n\'utilise aucun cookie, ni traceur publicitaire, ni '
            'mesure d\'audience. L\'application garde seulement sur votre '
            'appareil le jeton de votre session et le thème choisi, '
            'nécessaires à son fonctionnement.',
      ],
    ),
    LegalNoticeSection(
      title: 'Propriété intellectuelle',
      paragraphs: [
        'Le code source de FlorAccess est publié sur GitHub sous la licence '
            'GNU GPL version 3.',
      ],
    ),
  ];
}
