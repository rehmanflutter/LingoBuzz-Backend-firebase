import 'package:cloud_firestore/cloud_firestore.dart';

class GermanVocabularySetup {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String basePath = 'translation_languages/German/levels/A2/categories/Culture & Entertainment';

  // Helper function to format ID with leading zeros (e.g., 01, 02, 03)
  String _formatId(int id) {
     return id.toString().padLeft(2, '0');
   // return id.toString();
  }

// culture_and_entertainment.dart

// Category: Culture & Entertainment

  final List<Map<String, dynamic>> words = [
    {
      "id": 1,
      "german": "Dokumentarfilm",
      "english": "Documentary film",
      "spanish": "Documentary film",
      "french": "Documentary film",
      "italian": "Documentary film",
      "portuguese": "Documentary film",
      "chinese": "Documentary film",
      "korean": "Documentary film"
    },
    {
      "id": 2,
      "german": "Soundtrack",
      "english": "Soundtrack",
      "spanish": "Soundtrack",
      "french": "Soundtrack",
      "italian": "Soundtrack",
      "portuguese": "Soundtrack",
      "chinese": "Soundtrack",
      "korean": "Soundtrack"
    },
    {
      "id": 3,
      "german": "Spezialeffekte",
      "english": "Special effects",
      "spanish": "especial",
      "french": "spécial",
      "italian": "speciale",
      "portuguese": "especial",
      "chinese": "特别",
      "korean": "특별한"
    },
    {
      "id": 4,
      "german": "Probe",
      "english": "Rehearsal",
      "spanish": "Rehearsal",
      "french": "Rehearsal",
      "italian": "Rehearsal",
      "portuguese": "Rehearsal",
      "chinese": "Rehearsal",
      "korean": "Rehearsal"
    },
    {
      "id": 5,
      "german": "Bühnenbild",
      "english": "Set / scenery",
      "spanish": "Set / scenery",
      "french": "Set / scenery",
      "italian": "Set / scenery",
      "portuguese": "Set / scenery",
      "chinese": "Set / scenery",
      "korean": "Set / scenery"
    },
    {
      "id": 6,
      "german": "Kostüm",
      "english": "Costume",
      "spanish": "Costume",
      "french": "Costume",
      "italian": "Costume",
      "portuguese": "Costume",
      "chinese": "Costume",
      "korean": "Costume"
    },
    {
      "id": 7,
      "german": "Bühnenbildner",
      "english": "Set designer",
      "spanish": "Set designer",
      "french": "Set designer",
      "italian": "Set designer",
      "portuguese": "Set designer",
      "chinese": "Set designer",
      "korean": "Set designer"
    },
    {
      "id": 8,
      "german": "Kameramann",
      "english": "Cameraman",
      "spanish": "Cameraman",
      "french": "Cameraman",
      "italian": "Cameraman",
      "portuguese": "Cameraman",
      "chinese": "Cameraman",
      "korean": "Cameraman"
    },
    {
      "id": 9,
      "german": "Filmkamera",
      "english": "Film camera",
      "spanish": "Film camera",
      "french": "Film camera",
      "italian": "Film camera",
      "portuguese": "Film camera",
      "chinese": "Film camera",
      "korean": "Film camera"
    },
    {
      "id": 10,
      "german": "Schnitt",
      "english": "Editing",
      "spanish": "Editing",
      "french": "Editing",
      "italian": "Editing",
      "portuguese": "Editing",
      "chinese": "Editing",
      "korean": "Editing"
    },
    {
      "id": 11,
      "german": "Casting",
      "english": "Casting",
      "spanish": "Casting",
      "french": "Casting",
      "italian": "Casting",
      "portuguese": "Casting",
      "chinese": "Casting",
      "korean": "Casting"
    },
    {
      "id": 12,
      "german": "Besetzung",
      "english": "Cast",
      "spanish": "Cast",
      "french": "Cast",
      "italian": "Cast",
      "portuguese": "Cast",
      "chinese": "Cast",
      "korean": "Cast"
    },
    {
      "id": 13,
      "german": "Filmkritiker",
      "english": "Film critic",
      "spanish": "Film critic",
      "french": "Film critic",
      "italian": "Film critic",
      "portuguese": "Film critic",
      "chinese": "Film critic",
      "korean": "Film critic"
    },
    {
      "id": 14,
      "german": "Vorführung",
      "english": "Screening",
      "spanish": "Screening",
      "french": "Screening",
      "italian": "Screening",
      "portuguese": "Screening",
      "chinese": "Screening",
      "korean": "Screening"
    },
    {
      "id": 15,
      "german": "Premiere",
      "english": "Premiere",
      "spanish": "Premiere",
      "french": "Premiere",
      "italian": "Premiere",
      "portuguese": "Premiere",
      "chinese": "Premiere",
      "korean": "Premiere"
    },
    {
      "id": 16,
      "german": "Kulturelles Programm",
      "english": "Cultural program",
      "spanish": "Cultural program",
      "french": "Cultural program",
      "italian": "Cultural program",
      "portuguese": "Cultural program",
      "chinese": "Cultural program",
      "korean": "Cultural program"
    },
    {
      "id": 17,
      "german": "Künstlerresidenz",
      "english": "Artist residency",
      "spanish": "Artist residency",
      "french": "Artist residency",
      "italian": "Artist residency",
      "portuguese": "Artist residency",
      "chinese": "Artist residency",
      "korean": "Artist residency"
    },
    {
      "id": 18,
      "german": "Atelier",
      "english": "Artist’s studio",
      "spanish": "Artist’s studio",
      "french": "Artist’s studio",
      "italian": "Artist’s studio",
      "portuguese": "Artist’s studio",
      "chinese": "Artist’s studio",
      "korean": "Artist’s studio"
    },
    {
      "id": 19,
      "german": "Multimediale Performance",
      "english": "Multimedia performance",
      "spanish": "Multimedia performance",
      "french": "Multimedia performance",
      "italian": "Multimedia performance",
      "portuguese": "Multimedia performance",
      "chinese": "Multimedia performance",
      "korean": "Multimedia performance"
    },
    {
      "id": 20,
      "german": "Klanginstallation",
      "english": "Sound installation",
      "spanish": "sonar",
      "french": "sonner",
      "italian": "suonare",
      "portuguese": "soar",
      "chinese": "听起来",
      "korean": "들리다"
    },
    {
      "id": 21,
      "german": "Interaktive Ausstellung",
      "english": "Interactive exhibition",
      "spanish": "Interactive exhibition",
      "french": "Interactive exhibition",
      "italian": "Interactive exhibition",
      "portuguese": "Interactive exhibition",
      "chinese": "Interactive exhibition",
      "korean": "Interactive exhibition"
    },
    {
      "id": 22,
      "german": "Offizielle Eröffnung",
      "english": "Official opening",
      "spanish": "Official opening",
      "french": "Official opening",
      "italian": "Official opening",
      "portuguese": "Official opening",
      "chinese": "Official opening",
      "korean": "Official opening"
    },
    {
      "id": 23,
      "german": "Zeitgenössischer Künstler",
      "english": "Contemporary artist",
      "spanish": "Contemporary artist",
      "french": "Contemporary artist",
      "italian": "Contemporary artist",
      "portuguese": "Contemporary artist",
      "chinese": "Contemporary artist",
      "korean": "Contemporary artist"
    },
    {
      "id": 24,
      "german": "Dauerausstellung",
      "english": "Permanent collection",
      "spanish": "Permanent collection",
      "french": "Permanent collection",
      "italian": "Permanent collection",
      "portuguese": "Permanent collection",
      "chinese": "Permanent collection",
      "korean": "Permanent collection"
    },
    {
      "id": 25,
      "german": "Bildende Kunst",
      "english": "Visual arts",
      "spanish": "Visual arts",
      "french": "Visual arts",
      "italian": "Visual arts",
      "portuguese": "Visual arts",
      "chinese": "Visual arts",
      "korean": "Visual arts"
    },
    {
      "id": 26,
      "german": "Digitale Kunst",
      "english": "Digital arts",
      "spanish": "Digital arts",
      "french": "Digital arts",
      "italian": "Digital arts",
      "portuguese": "Digital arts",
      "chinese": "Digital arts",
      "korean": "Digital arts"
    },
    {
      "id": 27,
      "german": "Darstellende Kunst",
      "english": "Performing arts",
      "spanish": "Performing arts",
      "french": "Performing arts",
      "italian": "Performing arts",
      "portuguese": "Performing arts",
      "chinese": "Performing arts",
      "korean": "Performing arts"
    },
    {
      "id": 28,
      "german": "Kreatives Schreiben",
      "english": "Creative writing",
      "spanish": "Creative writing",
      "french": "Creative writing",
      "italian": "Creative writing",
      "portuguese": "Creative writing",
      "chinese": "Creative writing",
      "korean": "Creative writing"
    },
    {
      "id": 29,
      "german": "Schreibwerkstatt",
      "english": "Writing workshop",
      "spanish": "Writing workshop",
      "french": "Writing workshop",
      "italian": "Writing workshop",
      "portuguese": "Writing workshop",
      "chinese": "Writing workshop",
      "korean": "Writing workshop"
    },
    {
      "id": 30,
      "german": "Interaktive Lesung",
      "english": "Interactive reading",
      "spanish": "Interactive reading",
      "french": "Interactive reading",
      "italian": "Interactive reading",
      "portuguese": "Interactive reading",
      "chinese": "Interactive reading",
      "korean": "Interactive reading"
    },
    {
      "id": 31,
      "german": "Poesieclub",
      "english": "Poetry club",
      "spanish": "Poetry club",
      "french": "Poetry club",
      "italian": "Poetry club",
      "portuguese": "Poetry club",
      "chinese": "Poetry club",
      "korean": "Poetry club"
    },
    {
      "id": 32,
      "german": "Autorentreffen",
      "english": "Author discussion",
      "spanish": "Author discussion",
      "french": "Author discussion",
      "italian": "Author discussion",
      "portuguese": "Author discussion",
      "chinese": "Author discussion",
      "korean": "Author discussion"
    },
    {
      "id": 33,
      "german": "Literaturpreis",
      "english": "Literary prize",
      "spanish": "Literary prize",
      "french": "Literary prize",
      "italian": "Literary prize",
      "portuguese": "Literary prize",
      "chinese": "Literary prize",
      "korean": "Literary prize"
    },
    {
      "id": 34,
      "german": "Publikation",
      "english": "Publication",
      "spanish": "Publication",
      "french": "Publication",
      "italian": "Publication",
      "portuguese": "Publication",
      "chinese": "Publication",
      "korean": "Publication"
    },
    {
      "id": 35,
      "german": "Verleger",
      "english": "Publisher",
      "spanish": "Publisher",
      "french": "Publisher",
      "italian": "Publisher",
      "portuguese": "Publisher",
      "chinese": "Publisher",
      "korean": "Publisher"
    },
    {
      "id": 36,
      "german": "Biografie",
      "english": "Biography",
      "spanish": "Biography",
      "french": "Biography",
      "italian": "Biography",
      "portuguese": "Biography",
      "chinese": "Biography",
      "korean": "Biography"
    },
    {
      "id": 37,
      "german": "Romanautor",
      "english": "Novelist",
      "spanish": "Novelist",
      "french": "Novelist",
      "italian": "Novelist",
      "portuguese": "Novelist",
      "chinese": "Novelist",
      "korean": "Novelist"
    },
    {
      "id": 38,
      "german": "Dichter",
      "english": "Poet",
      "spanish": "Poet",
      "french": "Poet",
      "italian": "Poet",
      "portuguese": "Poet",
      "chinese": "Poet",
      "korean": "Poet"
    },
    {
      "id": 39,
      "german": "Redakteur",
      "english": "Editor / writer",
      "spanish": "Editor / writer",
      "french": "Editor / writer",
      "italian": "Editor / writer",
      "portuguese": "Editor / writer",
      "chinese": "Editor / writer",
      "korean": "Editor / writer"
    },
    {
      "id": 40,
      "german": "Ausstellungskritik",
      "english": "Exhibition critique",
      "spanish": "Exhibition critique",
      "french": "Exhibition critique",
      "italian": "Exhibition critique",
      "portuguese": "Exhibition critique",
      "chinese": "Exhibition critique",
      "korean": "Exhibition critique"
    },
    {
      "id": 41,
      "german": "Kulturelle Aktivität",
      "english": "Cultural activity",
      "spanish": "Cultural activity",
      "french": "Cultural activity",
      "italian": "Cultural activity",
      "portuguese": "Cultural activity",
      "chinese": "Cultural activity",
      "korean": "Cultural activity"
    },
    {
      "id": 42,
      "german": "Kunstverkauf",
      "english": "Art sale",
      "spanish": "Art sale",
      "french": "Art sale",
      "italian": "Art sale",
      "portuguese": "Art sale",
      "chinese": "Art sale",
      "korean": "Art sale"
    },
    {
      "id": 43,
      "german": "Private Sammlung",
      "english": "Private collection",
      "spanish": "Private collection",
      "french": "Private collection",
      "italian": "Private collection",
      "portuguese": "Private collection",
      "chinese": "Private collection",
      "korean": "Private collection"
    },
    {
      "id": 44,
      "german": "Straßenkunst",
      "english": "Street art",
      "spanish": "calle",
      "french": "rue",
      "italian": "strada",
      "portuguese": "rua",
      "chinese": "街道",
      "korean": "거리"
    },
    {
      "id": 45,
      "german": "Experimentelles Theater",
      "english": "Experimental theatre",
      "spanish": "Experimental theatre",
      "french": "Experimental theatre",
      "italian": "Experimental theatre",
      "portuguese": "Experimental theatre",
      "chinese": "Experimental theatre",
      "korean": "Experimental theatre"
    },
    {
      "id": 46,
      "german": "Kulturelles Ereignis",
      "english": "Cultural event",
      "spanish": "Cultural event",
      "french": "Cultural event",
      "italian": "Cultural event",
      "portuguese": "Cultural event",
      "chinese": "Cultural event",
      "korean": "Cultural event"
    },
    {
      "id": 47,
      "german": "Musikproduktion",
      "english": "Music production",
      "spanish": "Music production",
      "french": "Music production",
      "italian": "Music production",
      "portuguese": "Music production",
      "chinese": "Music production",
      "korean": "Music production"
    },
    {
      "id": 48,
      "german": "Orchesterkomposition",
      "english": "Orchestral composition",
      "spanish": "Orchestral composition",
      "french": "Orchestral composition",
      "italian": "Orchestral composition",
      "portuguese": "Orchestral composition",
      "chinese": "Orchestral composition",
      "korean": "Orchestral composition"
    },
    {
      "id": 49,
      "german": "Experimentelles Konzert",
      "english": "Experimental concert",
      "spanish": "Experimental concert",
      "french": "Experimental concert",
      "italian": "Experimental concert",
      "portuguese": "Experimental concert",
      "chinese": "Experimental concert",
      "korean": "Experimental concert"
    },
    {
      "id": 50,
      "german": "Videoinstallation",
      "english": "Video installation",
      "spanish": "Video installation",
      "french": "Video installation",
      "italian": "Video installation",
      "portuguese": "Video installation",
      "chinese": "Video installation",
      "korean": "Video installation"
    },
    {
      "id": 51,
      "german": "Kunstforschung",
      "english": "Artistic research",
      "spanish": "Artistic research",
      "french": "Artistic research",
      "italian": "Artistic research",
      "portuguese": "Artistic research",
      "chinese": "Artistic research",
      "korean": "Artistic research"
    }
  ];

  final List<Map<String, dynamic>> sentences = [
    {
      "id": 1,
      "german": "Komparse",
      "english": "Extra / background actor",
      "spanish": "Extra / background actor",
      "french": "Extra / background actor",
      "italian": "Extra / background actor",
      "portuguese": "Extra / background actor",
      "chinese": "Extra / background actor",
      "korean": "Extra / background actor"
    },
    {
      "id": 2,
      "german": "Regieleitung",
      "english": "Director / stage direction",
      "spanish": "Director / stage direction",
      "french": "Director / stage direction",
      "italian": "Director / stage direction",
      "portuguese": "Director / stage direction",
      "chinese": "Director / stage direction",
      "korean": "Director / stage direction"
    },
    {
      "id": 3,
      "german": "Teilnahme des Publikums",
      "english": "Public participation",
      "spanish": "Public participation",
      "french": "Public participation",
      "italian": "Public participation",
      "portuguese": "Public participation",
      "chinese": "Public participation",
      "korean": "Public participation"
    },
    {
      "id": 4,
      "german": "Digitale Kunstwerke",
      "english": "Interactive digital arts",
      "spanish": "Interactive digital arts",
      "french": "Interactive digital arts",
      "italian": "Interactive digital arts",
      "portuguese": "Interactive digital arts",
      "chinese": "Interactive digital arts",
      "korean": "Interactive digital arts"
    },
    {
      "id": 5,
      "german": "Immersive Kunst",
      "english": "Immersive visual arts",
      "spanish": "Immersive visual arts",
      "french": "Immersive visual arts",
      "italian": "Immersive visual arts",
      "portuguese": "Immersive visual arts",
      "chinese": "Immersive visual arts",
      "korean": "Immersive visual arts"
    },
    {
      "id": 6,
      "german": "Augmented Reality Performance",
      "english": "Augmented reality performance",
      "spanish": "Augmented reality performance",
      "french": "Augmented reality performance",
      "italian": "Augmented reality performance",
      "portuguese": "Augmented reality performance",
      "chinese": "Augmented reality performance",
      "korean": "Augmented reality performance"
    },
    {
      "id": 7,
      "german": "Festival für darstellende Kunst",
      "english": "Performing arts festival",
      "spanish": "Performing arts festival",
      "french": "Performing arts festival",
      "italian": "Performing arts festival",
      "portuguese": "Performing arts festival",
      "chinese": "Performing arts festival",
      "korean": "Performing arts festival"
    },
    {
      "id": 8,
      "german": "Kritik in der Fachpresse",
      "english": "Art criticism",
      "spanish": "Art criticism",
      "french": "Art criticism",
      "italian": "Art criticism",
      "portuguese": "Art criticism",
      "chinese": "Art criticism",
      "korean": "Art criticism"
    },
    {
      "id": 9,
      "german": "Internationale Künstlerresidenz",
      "english": "International artist residency",
      "spanish": "International artist residency",
      "french": "International artist residency",
      "italian": "International artist residency",
      "portuguese": "International artist residency",
      "chinese": "International artist residency",
      "korean": "International artist residency"
    },
    {
      "id": 10,
      "german": "Der Regisseur bereitet einen Dokumentarfilm vor.",
      "english": "The director is preparing a documentary.",
      "spanish": "The director is preparing a documentary.",
      "french": "The director is preparing a documentary.",
      "italian": "The director is preparing a documentary.",
      "portuguese": "The director is preparing a documentary.",
      "chinese": "The director is preparing a documentary.",
      "korean": "The director is preparing a documentary."
    },
    {
      "id": 11,
      "german": "Der Schnitt des Films dauert mehrere Wochen.",
      "english": "The editing of the film takes several weeks.",
      "spanish": "The editing of the film takes several weeks.",
      "french": "The editing of the film takes several weeks.",
      "italian": "The editing of the film takes several weeks.",
      "portuguese": "The editing of the film takes several weeks.",
      "chinese": "The editing of the film takes several weeks.",
      "korean": "The editing of the film takes several weeks."
    },
    {
      "id": 12,
      "german": "Die Komparsen proben ihre Szenen.",
      "english": "The extras are rehearsing their scenes.",
      "spanish": "The extras are rehearsing their scenes.",
      "french": "The extras are rehearsing their scenes.",
      "italian": "The extras are rehearsing their scenes.",
      "portuguese": "The extras are rehearsing their scenes.",
      "chinese": "The extras are rehearsing their scenes.",
      "korean": "The extras are rehearsing their scenes."
    },
    {
      "id": 13,
      "german": "Die Theatergruppe tritt jeden Abend auf.",
      "english": "The theatre troupe performs every evening.",
      "spanish": "The theatre troupe performs every evening.",
      "french": "The theatre troupe performs every evening.",
      "italian": "The theatre troupe performs every evening.",
      "portuguese": "The theatre troupe performs every evening.",
      "chinese": "The theatre troupe performs every evening.",
      "korean": "The theatre troupe performs every evening."
    },
    {
      "id": 14,
      "german": "Der Fotograf fotografiert städtische Landschaften.",
      "english": "The photographer captures urban landscapes.",
      "spanish": "The photographer captures urban landscapes.",
      "french": "The photographer captures urban landscapes.",
      "italian": "The photographer captures urban landscapes.",
      "portuguese": "The photographer captures urban landscapes.",
      "chinese": "The photographer captures urban landscapes.",
      "korean": "The photographer captures urban landscapes."
    },
    {
      "id": 15,
      "german": "Das internationale Festival zieht Besucher aus aller Welt an.",
      "english": "The international festival attracts visitors from all over the world.",
      "spanish": "The international festival attracts visitors from all over the world.",
      "french": "The international festival attracts visitors from all over the world.",
      "italian": "The international festival attracts visitors from all over the world.",
      "portuguese": "The international festival attracts visitors from all over the world.",
      "chinese": "The international festival attracts visitors from all over the world.",
      "korean": "The international festival attracts visitors from all over the world."
    },
    {
      "id": 16,
      "german": "Der Solist spielt die Geige wunderschön.",
      "english": "The soloist plays the violin beautifully.",
      "spanish": "The soloist plays the violin beautifully.",
      "french": "The soloist plays the violin beautifully.",
      "italian": "The soloist plays the violin beautifully.",
      "portuguese": "The soloist plays the violin beautifully.",
      "chinese": "The soloist plays the violin beautifully.",
      "korean": "The soloist plays the violin beautifully."
    },
    {
      "id": 17,
      "german": "Wir haben eine künstlerische Performance besucht.",
      "english": "We attended an artistic performance.",
      "spanish": "We attended an artistic performance.",
      "french": "We attended an artistic performance.",
      "italian": "We attended an artistic performance.",
      "portuguese": "We attended an artistic performance.",
      "chinese": "We attended an artistic performance.",
      "korean": "We attended an artistic performance."
    },
    {
      "id": 18,
      "german": "Die interaktive Ausstellung ist sehr lehrreich.",
      "english": "The interactive exhibition is very educational.",
      "spanish": "The interactive exhibition is very educational.",
      "french": "The interactive exhibition is very educational.",
      "italian": "The interactive exhibition is very educational.",
      "portuguese": "The interactive exhibition is very educational.",
      "chinese": "The interactive exhibition is very educational.",
      "korean": "The interactive exhibition is very educational."
    },
    {
      "id": 19,
      "german": "Der Literaturpreis wurde gestern verliehen.",
      "english": "The literary prize was awarded yesterday.",
      "spanish": "The literary prize was awarded yesterday.",
      "french": "The literary prize was awarded yesterday.",
      "italian": "The literary prize was awarded yesterday.",
      "portuguese": "The literary prize was awarded yesterday.",
      "chinese": "The literary prize was awarded yesterday.",
      "korean": "The literary prize was awarded yesterday."
    },
    {
      "id": 20,
      "german": "Die Musiker proben für das Open-Air-Konzert.",
      "english": "The musicians are rehearsing for the open-air concert.",
      "spanish": "The musicians are rehearsing for the open-air concert.",
      "french": "The musicians are rehearsing for the open-air concert.",
      "italian": "The musicians are rehearsing for the open-air concert.",
      "portuguese": "The musicians are rehearsing for the open-air concert.",
      "chinese": "The musicians are rehearsing for the open-air concert.",
      "korean": "The musicians are rehearsing for the open-air concert."
    },
    {
      "id": 21,
      "german": "Die Erzählung des Films ist fesselnd.",
      "english": "The narration of the film is captivating.",
      "spanish": "The narration of the film is captivating.",
      "french": "The narration of the film is captivating.",
      "italian": "The narration of the film is captivating.",
      "portuguese": "The narration of the film is captivating.",
      "chinese": "The narration of the film is captivating.",
      "korean": "The narration of the film is captivating."
    },
    {
      "id": 22,
      "german": "Der Literaturkritiker hat seinen Artikel veröffentlicht.",
      "english": "The literary critic published their article.",
      "spanish": "The literary critic published their article.",
      "french": "The literary critic published their article.",
      "italian": "The literary critic published their article.",
      "portuguese": "The literary critic published their article.",
      "chinese": "The literary critic published their article.",
      "korean": "The literary critic published their article."
    },
    {
      "id": 23,
      "german": "Die Besucher nehmen am kreativen Workshop teil.",
      "english": "Visitors participate in the creative workshop.",
      "spanish": "Visitors participate in the creative workshop.",
      "french": "Visitors participate in the creative workshop.",
      "italian": "Visitors participate in the creative workshop.",
      "portuguese": "Visitors participate in the creative workshop.",
      "chinese": "Visitors participate in the creative workshop.",
      "korean": "Visitors participate in the creative workshop."
    },
    {
      "id": 24,
      "german": "Der Kunstverkauf zeigt zeitgenössische Werke.",
      "english": "The art sale features contemporary works.",
      "spanish": "The art sale features contemporary works.",
      "french": "The art sale features contemporary works.",
      "italian": "The art sale features contemporary works.",
      "portuguese": "The art sale features contemporary works.",
      "chinese": "The art sale features contemporary works.",
      "korean": "The art sale features contemporary works."
    }
  ];


  // Function to add words to Firestore with padded IDs
  Future<void> addWords() async {
    try {
      print('Starting to add words...');

      for (var word in words) {
        final numericId = word['id'] as int;
        final docId = _formatId(numericId); // Format with leading zeros
        final wordData = Map<String, dynamic>.from(word);
        wordData.remove('id'); // Remove id from data
        wordData['id'] = numericId; // Add numeric order field for sorting if needed

        await _firestore
            .collection('$basePath/phrases')
            .doc(docId)
            .set(wordData);
        print('Added word $docId: ${word['english']}');
      }

      print('✅ Successfully added all ${words.length} words!');
    } catch (e) {
      print('❌ Error adding words: $e');
      rethrow;
    }
  }

  // Function to add sentences to Firestore with padded IDs
  Future<void> addSentences() async {
    try {
      print('Starting to add sentences...');

      for (var sentence in sentences) {
        final numericId = sentence['id'] as int;
        final docId = _formatId(numericId); // Format with leading zeros
        final sentenceData = Map<String, dynamic>.from(sentence);
        sentenceData.remove('id'); // Remove id from data
        sentenceData['id'] = numericId; // Add numeric order field for sorting if needed

        await _firestore
            .collection('$basePath/sentences')
            .doc(docId)
            .set(sentenceData);

        print('Added sentence $docId: ${sentence['english']}');
      }

      print('✅ Successfully added all ${sentences.length} sentences!');
    } catch (e) {
      print('❌ Error adding sentences: $e');
      rethrow;
    }
  }

  // Function to add all data (words + sentences)
  Future<void> addAllData() async {
    try {
      print('========================================');
      print('Starting complete data upload...');
      print('========================================\n');

      await addWords();
      print('');
      await addSentences();

      print('\n========================================');
      print('✅ ALL DATA UPLOADED SUCCESSFULLY!');
      print('Total words: ${words.length}');
      print('Total sentences: ${sentences.length}');
      print('Total items: ${words.length + sentences.length}');
      print('========================================');
    } catch (e) {
      print('\n========================================');
      print('❌ ERROR DURING UPLOAD');
      print('Error: $e');
      print('========================================');
      rethrow;
    }
  }
}