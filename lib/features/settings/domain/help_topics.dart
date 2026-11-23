import 'package:material_ui/material_ui.dart';

final class HelpTopic {
  const HelpTopic({
    required this.id,
    required this.order,
    required this.icon,
    required this.titleEn,
    required this.titleGu,
    required this.summaryEn,
    required this.summaryGu,
    required this.whenToUseEn,
    required this.whenToUseGu,
    required this.stepsEn,
    required this.stepsGu,
    required this.exampleEn,
    required this.exampleGu,
  });

  final String id;
  final int order;
  final IconData icon;
  final String titleEn;
  final String titleGu;
  final String summaryEn;
  final String summaryGu;
  final String whenToUseEn;
  final String whenToUseGu;
  final List<String> stepsEn;
  final List<String> stepsGu;
  final String exampleEn;
  final String exampleGu;

  String title(String localeCode) => localeCode == 'gu' ? titleGu : titleEn;
  String summary(String localeCode) =>
      localeCode == 'gu' ? summaryGu : summaryEn;
  String whenToUse(String localeCode) =>
      localeCode == 'gu' ? whenToUseGu : whenToUseEn;
  List<String> steps(String localeCode) =>
      localeCode == 'gu' ? stepsGu : stepsEn;
  String example(String localeCode) =>
      localeCode == 'gu' ? exampleGu : exampleEn;

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      titleEn,
      titleGu,
      summaryEn,
      summaryGu,
      whenToUseEn,
      whenToUseGu,
      ...stepsEn,
      ...stepsGu,
      exampleEn,
      exampleGu,
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }
}

/// Complete 19-topic practical garment workshop guidance catalog in English & Gujarati.
abstract final class StitchFlowHelpCatalog {
  static const List<HelpTopic> topics = <HelpTopic>[
    HelpTopic(
      id: 'getting-started',
      order: 1,
      icon: Icons.rocket_launch_outlined,
      titleEn: 'Getting Started with StitchFlow',
      titleGu: 'સ્ટિચફ્લોની શરૂઆત કેવી રીતે કરવી',
      summaryEn: 'Recommended 5-minute setup order to start tracking garment lots, stock, and worker accounts offline.',
      summaryGu: 'ગાર્મેન્ટ લોટ્સ, સ્ટોક અને કારીગર હિસાબ ઓફલાઇન શરૂ કરવાનો સરળ ૫-મિનિટનો ક્રમ.',
      whenToUseEn:
          'When opening StitchFlow for the first time in your workshop.',
      whenToUseGu: 'તમારા કારખાનામાં પહેલી વાર સ્ટિચફ્લો શરૂ કરો ત્યારે.',
      stepsEn: [
        'Open Settings -> Business Profile and enter your workshop name (English & Gujarati), owner name, and default billing mode.',
        'Create your production processes (e.g. Cutting, Stitching, Press, Finishing).',
        'Add your workshop workers and assign each worker to the processes they handle.',
        'Configure effective-dated per-piece rates for each worker and process.',
        'Create your first Lot, add Designs & Colours with initial piece quantities, and start issuing stock.',
      ],
      stepsGu: [
        'સેટિંગ્સ -> બિઝનેસ પ્રોફાઇલ ખોલીને કારખાનાનું નામ (અંગ્રેજી અને ગુજરાતી), માલિકનું નામ અને ડિફોલ્ટ બિલિંગ નિયમ સાચવો.',
        'તમારી પ્રોડક્શન પ્રક્રિયાઓ બનાવો (દા.ત. કટિંગ, સ્ટિચિંગ, પ્રેસ, ફિનિશિંગ).',
        'કારીગરો ઉમેરો અને દરેક કારીગરને તેમની પ્રક્રિયાઓ સોંપો.',
        'દરેક કારીગર અને પ્રક્રિયા માટે અમલી તારીખ સાથે પીસ દીઠ ભાવ સેટ કરો.',
        'તમારો પહેલો લોટ બનાવો, ડિઝાઇન અને રંગનો પ્રારંભિક જથ્થો ઉમેરો અને સ્ટોક આપવાનું શરૂ કરો.',
      ],
      exampleEn: 'Setup once: Cutting + Stitching -> Worker Rajesh (assigned to Stitching at ₹25/pc) -> Lot L-101 (100 pcs) -> Ready for daily Issue & Return.',
      exampleGu: 'એક વખત સેટઅપ: કટિંગ + સ્ટિચિંગ -> કારીગર રાજેશ (સ્ટિચિંગ ₹25/પીસ) -> લોટ L-101 (100 પીસ) -> રોજિંદા ઇશ્યૂ અને પરત માટે તૈયાર.',
    ),
    HelpTopic(
      id: 'creating-a-lot',
      order: 2,
      icon: Icons.inventory_2_outlined,
      titleEn: 'Creating a Lot',
      titleGu: 'નવો લોટ બનાવવો',
      summaryEn: 'Group each incoming fabric batch or production order under a unique Lot Number with optional photos.',
      summaryGu: 'દરેક નવા કાપડ બેચ અથવા પ્રોડક્શન ઓર્ડરને અલગ લોટ નંબર અને ફોટા સાથે નોંધો.',
      whenToUseEn: 'Whenever new fabric or a new production batch arrives in your workshop.',
      whenToUseGu:
          'જ્યારે કારખાનામાં નવો માલ અથવા નવો પ્રોડક્શન બેચ આવે ત્યારે.',
      stepsEn: [
        'Open the Lots tab from the bottom bar and tap New Lot.',
        'Enter a unique Lot Number (e.g. LOT-2026-01), optional Title, IST Lot Date, and Notes.',
        'Tap Save to create the lot, then tap the lot card to open its details.',
        'Optionally attach reference photos using Camera or Gallery — photos are stored privately offline.',
      ],
      stepsGu: [
        'નીચેના મેનુમાંથી લોટ્સ ટેબ ખોલો અને "નવો લોટ" પર ટેપ કરો.',
        'અલગ લોટ નંબર (દા.ત. LOT-2026-01), વૈકલ્પિક શીર્ષક, IST તારીખ અને નોંધ દાખલ કરો.',
        'સાચવો પર ટેપ કરો અને વિગતો જોવા માટે લોટ કાર્ડ ખોલો.',
        'જરૂર હોય તો કેમેરા અથવા ગેલેરીથી લોટના ફોટા જોડો — ફોટા ઓફલાઇન સુરક્ષિત રહે છે.',
      ],
      exampleEn: 'Lot "SF-104", Title "Diwali Kurti Batch", Date today, with 2 fabric sample photos attached.',
      exampleGu: 'લોટ "SF-104", શીર્ષક "દિવાળી કુર્તી બેચ", આજની તારીખ અને કાપડના ૨ ફોટા.',
    ),
    HelpTopic(
      id: 'designs-and-colours',
      order: 3,
      icon: Icons.palette_outlined,
      titleEn: 'Adding Designs & Colours',
      titleGu: 'ડિઝાઇન અને રંગ ઉમેરવા',
      summaryEn: 'Define nested designs inside a lot and record independent initial quantities and prices per colour.',
      summaryGu: 'લોટની અંદર ડિઝાઇન ઉમેરો અને દરેક રંગનો અલગ પ્રારંભિક જથ્થો તથા ભાવ નોંધો.',
      whenToUseEn: 'Right after creating a lot so pieces become available in in-house good stock.',
      whenToUseGu:
          'લોટ બનાવ્યા પછી તરત, જેથી પીસ ઇન-હાઉસ સારા સ્ટોકમાં ઉપલબ્ધ બને.',
      stepsEn: [
        'Open a Lot from the Lots tab and tap Add Design.',
        'Enter the Design Name / Code (e.g. D-101) and tap Save.',
        'Inside the design card, tap Add Colour.',
        'Enter the Colour Name (e.g. Maroon), Initial Quantity (in pieces), and Price per Piece (₹), then Save.',
      ],
      stepsGu: [
        'લોટ્સ ટેબમાંથી લોટ ખોલો અને "ડિઝાઇન ઉમેરો" પર ટેપ કરો.',
        'ડિઝાઇનનું નામ / કોડ (દા.ત. D-101) દાખલ કરી સાચવો.',
        'ડિઝાઇન કાર્ડમાં "કલર ઉમેરો" પર ટેપ કરો.',
        'રંગનું નામ (દા.ત. મરૂન), પ્રારંભિક જથ્થો (પીસ) અને પીસ દીઠ ભાવ (₹) દાખલ કરી સાચવો.',
      ],
      exampleEn: 'Lot SF-104 -> Design D-101 -> Maroon (120 pcs @ ₹350) and Navy (80 pcs @ ₹350). Both start as Available Good Stock.',
      exampleGu: 'લોટ SF-104 -> ડિઝાઇન D-101 -> મરૂન (120 પીસ @ ₹350) અને નેવી (80 પીસ @ ₹350). બંને સારા સ્ટોકમાં ઉપલબ્ધ થશે.',
    ),
    HelpTopic(
      id: 'creating-processes',
      order: 4,
      icon: Icons.precision_manufacturing_outlined,
      titleEn: 'Creating Production Processes',
      titleGu: 'પ્રોડક્શન પ્રક્રિયાઓ બનાવવી',
      summaryEn: 'Create any custom workshop stages with zero forced sequence and optional process-specific labour rules.',
      summaryGu: 'કોઈપણ નક્કી ક્રમ વગર તમારા કારખાનાની પ્રક્રિયાઓ અને ખાસ મજૂરી નિયમો બનાવો.',
      whenToUseEn: 'During initial setup or whenever you add a new stage such as Embroidery or Steam Press.',
      whenToUseGu: 'શરૂઆતના સેટઅપ વખતે અથવા એમ્બ્રોઇડરી કે પ્રેસ જેવી નવી પ્રક્રિયા ઉમેરવી હોય ત્યારે.',
      stepsEn: [
        'Open Processes from the Dashboard Quick Actions or side menu and tap New Process.',
        'Enter the Process Name and optional description.',
        'Choose Labour Billing Mode: keep "Use Business Default" or override specifically for this process.',
        'Optionally enable "Include damaged pieces in labour" if workers are still paid for damaged pieces in this stage.',
      ],
      stepsGu: [
        'ડેશબોર્ડની ઝડપી ક્રિયાઓ અથવા મેનુમાંથી પ્રક્રિયાઓ ખોલો અને "નવી પ્રક્રિયા" પર ટેપ કરો.',
        'પ્રક્રિયાનું નામ અને વૈકલ્પિક વિગત દાખલ કરો.',
        'મજૂરી ગણતરી પદ્ધતિ પસંદ કરો: "બિઝનેસ ડિફોલ્ટ મુજબ" રાખો અથવા ખાસ બદલો.',
        'જો આ પ્રક્રિયામાં ડેમેજ પીસની મજૂરી પણ આપવાની હોય તો તે વિકલ્પ ચાલુ કરો.',
      ],
      exampleEn: 'Stitching uses Business Default (Pay on Received Good Qty), while Cutting overrides to Pay on Given Qty.',
      exampleGu: 'સ્ટિચિંગ બિઝનેસ ડિફોલ્ટ (મળેલા સારા જથ્થા પર) રાખે છે, જ્યારે કટિંગ આપેલા જથ્થા પર મજૂરી પસંદ કરે છે.',
    ),
    HelpTopic(
      id: 'adding-workers',
      order: 5,
      icon: Icons.people_outline,
      titleEn: 'Adding Workers',
      titleGu: 'કારીગરો ઉમેરવા',
      summaryEn: 'Maintain a clean directory of active and inactive workers with contact details and notes.',
      summaryGu: 'સક્રિય અને નિષ્ક્રિય કારીગરોની સંપર્ક વિગતો અને નોંધ સાથેની યાદી જાળવો.',
      whenToUseEn: 'Whenever a new tailor, cutter, presser, or job-worker joins your workshop.',
      whenToUseGu: 'જ્યારે નવા ટેઇલર, કટર, પ્રેસર કે જોબ-વર્કર તમારા કારખાનામાં જોડાય ત્યારે.',
      stepsEn: [
        'Open the Workers tab and tap New Worker.',
        'Enter the Worker Name (required), plus optional Phone, Address, and Notes.',
        'Tap Save. Inactive workers can be deactivated later without ever losing historical rates or ledgers.',
      ],
      stepsGu: [
        'કારીગરો ટેબ ખોલો અને "નવો કારીગર" પર ટેપ કરો.',
        'કારીગરનું નામ (ફરજિયાત), અને વૈકલ્પિક ફોન, સરનામું તથા નોંધ દાખલ કરો.',
        'સાચવો પર ટેપ કરો. પછીથી કોઈ કારીગર કામ છોડે તો હિસાબ ગુમાવ્યા વગર તેમને નિષ્ક્રિય કરી શકાય છે.',
      ],
      exampleEn: 'Add "Hasmukh Bhai" with phone number -> Ready for process assignment and rate setup.',
      exampleGu: '"હસમુખભાઈ" ને ફોન નંબર સાથે ઉમેરો -> હવે પ્રક્રિયા સોંપણી અને ભાવ સેટઅપ માટે તૈયાર.',
    ),
    HelpTopic(
      id: 'assigning-workers',
      order: 6,
      icon: Icons.link_rounded,
      titleEn: 'Assigning Workers to Processes',
      titleGu: 'કારીગરોને પ્રક્રિયા સોંપવી',
      summaryEn: 'Link each worker to one or more active processes so only eligible workers appear during stock issue.',
      summaryGu: 'દરેક કારીગરને એક કે વધુ સક્રિય પ્રક્રિયાઓ સાથે જોડો જેથી સ્ટોક આપતી વખતે માત્ર યોગ્ય કારીગરો જ દેખાય.',
      whenToUseEn: 'After adding a worker or when an existing worker starts handling another stage.',
      whenToUseGu: 'નવો કારીગર ઉમેર્યા પછી અથવા કારીગર બીજી પ્રક્રિયાનું કામ શરૂ કરે ત્યારે.',
      stepsEn: [
        'Open a Worker profile from the Workers tab.',
        'Tap Manage Assignments.',
        'Select an active process from the list and tap Assign Process.',
        'You can assign multiple processes to the same worker and remove assignments anytime without affecting past records.',
      ],
      stepsGu: [
        'કારીગરો ટેબમાંથી કારીગરની પ્રોફાઇલ ખોલો.',
        '"પ્રક્રિયા સોંપણી" પર ટેપ કરો.',
        'યાદીમાંથી સક્રિય પ્રક્રિયા પસંદ કરી "પ્રક્રિયા સોંપો" પર ટેપ કરો.',
        'એક જ કારીગરને એકથી વધુ પ્રક્રિયાઓ સોંપી શકાય છે અને જૂના રેકોર્ડને અસર કર્યા વગર દૂર પણ કરી શકાય છે.',
      ],
      exampleEn: 'Assign "Hasmukh Bhai" to both Stitching and Overlock. When issuing Stitching stock, he appears automatically.',
      exampleGu: '"હસમુખભાઈ" ને સ્ટિચિંગ અને ઓવરલોક બંને સોંપો. સ્ટિચિંગ સ્ટોક આપતી વખતે તેમનું નામ આપમેળે દેખાશે.',
    ),
    HelpTopic(
      id: 'setting-worker-rates',
      order: 7,
      icon: Icons.currency_rupee_rounded,
      titleEn: 'Setting Effective-Dated Worker Rates',
      titleGu: 'કારીગરના પીસ દીઠ ભાવ સેટ કરવા',
      summaryEn: 'Record historical per-piece rates with IST effective dates so old transactions never change when rates are revised.',
      summaryGu: 'IST અમલી તારીખ સાથે પીસ દીઠ ભાવ નોંધો જેથી ભાવ બદલાય ત્યારે જૂના હિસાબમાં કોઈ ફેરફાર ન થાય.',
      whenToUseEn: 'Before issuing stock to a worker for a process, or when revising a worker\'s piece rate.',
      whenToUseGu: 'કારીગરને પહેલી વાર સ્ટોક આપતા પહેલાં અથવા તેમના પીસ દીઠ ભાવમાં વધારો/ઘટાડો કરો ત્યારે.',
      stepsEn: [
        'Open the Worker profile and tap Add Rate (or Rate History).',
        'Choose the Process and enter the Rate per Piece (₹).',
        'Select the Effective From date (IST). Leave Effective To blank for an ongoing rate.',
        'When adding a newer rate later, StitchFlow safely offers to auto-close the previous ongoing rate on the day before.',
      ],
      stepsGu: [
        'કારીગરની પ્રોફાઇલ ખોલી "ભાવ ઉમેરો" (અથવા ભાવ ઇતિહાસ) પર ટેપ કરો.',
        'પ્રક્રિયા પસંદ કરો અને પીસ દીઠ ભાવ (₹) દાખલ કરો.',
        'અમલી તારીખ (IST) પસંદ કરો. ચાલુ ભાવ માટે અંતિમ તારીખ ખાલી રાખો.',
        'પછીથી નવો ભાવ ઉમેરો ત્યારે સ્ટિચફ્લો અગાઉનો ચાલુ ભાવ અગાઉના દિવસે આપમેળે બંધ કરવાની ખાતરી માંગે છે.',
      ],
      exampleEn: '₹20/pc from 2026-01-01 to 2026-03-31, then ₹24/pc from 2026-04-01 Ongoing. Issues in March lock ₹20; issues in April lock ₹24.',
      exampleGu: '2026-01-01 થી 2026-03-31 સુધી ₹20/પીસ, પછી 2026-04-01 થી ₹24/પીસ. માર્ચના ઇશ્યૂમાં ₹20 અને એપ્રિલમાં ₹24 લોક થશે.',
    ),
    HelpTopic(
      id: 'issuing-stock',
      order: 8,
      icon: Icons.outbox_rounded,
      titleEn: 'Issuing Stock to Workers',
      titleGu: 'કારીગરને સ્ટોક આપવો (ઇશ્યૂ)',
      summaryEn: 'Issue available in-house good stock to an assigned worker in 4 simple steps with automatic rate locking.',
      summaryGu: 'ઉપલબ્ધ સારા સ્ટોકમાંથી સોંપેલા કારીગરને આપમેળે ભાવ લોક સાથે ૪ સરળ સ્ટેપમાં માલ આપો.',
      whenToUseEn: 'Every time pieces leave your in-house table for a worker to perform a process.',
      whenToUseGu: 'જ્યારે પણ કારખાનામાંથી કોઈ પ્રક્રિયા માટે કારીગરને પીસ આપવામાં આવે ત્યારે.',
      stepsEn: [
        'Tap Issue Stock from the Dashboard or Stock tab.',
        'Step 1: Pick the Lot / Design / Colour (available good stock is shown clearly).',
        'Step 2: Pick the Active Process and Eligible Worker. Verify the locked rate & billing mode preview.',
        'Step 3: Enter the piece quantity (cannot exceed available good stock) and review the confirmation summary.',
        'Step 4: Tap Confirm & Issue Stock. From the success screen you can immediately issue more stock.',
      ],
      stepsGu: [
        'ડેશબોર્ડ અથવા સ્ટોક ટેબમાંથી "સ્ટોક આપો" પર ટેપ કરો.',
        'સ્ટેપ ૧: લોટ / ડિઝાઇન / રંગ પસંદ કરો (ઉપલબ્ધ સારો સ્ટોક સ્પષ્ટ દેખાશે).',
        'સ્ટેપ ૨: સક્રિય પ્રક્રિયા અને યોગ્ય કારીગર પસંદ કરો. લોક થતો ભાવ અને બિલિંગ નિયમ તપાસો.',
        'સ્ટેપ ૩: પીસની સંખ્યા દાખલ કરો (ઉપલબ્ધ સ્ટોકથી વધુ ન હોઈ શકે) અને સારાંશ ચકાસો.',
        'સ્ટેપ ૪: "ખાતરી કરી સ્ટોક આપો" પર ટેપ કરો. સફળતા સ્ક્રીન પરથી તરત વધુ સ્ટોક આપી શકાય છે.',
      ],
      exampleEn: 'Issue 50 pcs of Lot SF-104 Maroon to Rajesh for Stitching @ ₹25/pc. Available stock drops from 120 to 70, and Pending becomes 50.',
      exampleGu: 'લોટ SF-104 મરૂનના 50 પીસ રાજેશને સ્ટિચિંગ માટે ₹25/પીસના ભાવે આપો. ઉપલબ્ધ સ્ટોક 120 થી 70 થશે અને બાકી 50 બતાવશે.',
    ),
    HelpTopic(
      id: 'receiving-returns',
      order: 9,
      icon: Icons.assignment_returned_outlined,
      titleEn: 'Receiving Returned Stock',
      titleGu: 'કારીગર પાસેથી માલ પરત લેવો',
      summaryEn: 'Record full or partial returns against an open issue while seeing live remaining pending and labour impact.',
      summaryGu: 'બાકી ઇશ્યુ સામે સંપૂર્ણ કે આંશિક પરત નોંધો અને બાકી જથ્થો તથા મજૂરીની અસર લાઇવ જુઓ.',
      whenToUseEn: 'Whenever a worker brings back finished or partially completed pieces.',
      whenToUseGu: 'જ્યારે કારીગર તૈયાર અથવા આંશિક તૈયાર પીસ પરત લાવે ત્યારે.',
      stepsEn: [
        'Tap Receive Return from Dashboard or pick a card under Stock -> Pending Returns.',
        'Enter Good Returned pieces (tap "All Good" for quick full return), plus any Damaged, Lost, or Shortage quantities.',
        'Check the live Remaining Pending indicator and the "What Will Happen on Save" impact summary.',
        'Enter a mandatory Reason if any Damaged, Lost, or Shortage quantity is above 0.',
        'Tap Confirm & Save Return. Good pieces return to in-house stock and can immediately be issued to the next process.',
      ],
      stepsGu: [
        'ડેશબોર્ડમાંથી "માલ પરત લો" પર ટેપ કરો અથવા સ્ટોક -> બાકી પરતમાંથી કાર્ડ પસંદ કરો.',
        'સારો પરત જથ્થો દાખલ કરો (પૂરા માલ માટે "બધો સારો" ટેપ કરો), અને જરૂર હોય તો ડેમેજ, ખોવાયેલ કે ઘટ દાખલ કરો.',
        'લાઇવ બાકી જથ્થો અને "સાચવ્યા પછી થનાર અસર" સારાંશ તપાસો.',
        'જો ડેમેજ, ખોવાયેલ અથવા ઘટ ૦ થી વધુ હોય તો ફરજિયાત કારણ લખો.',
        '"ખાતરી કરી પરત સાચવો" ટેપ કરો. સારા પીસ પાછા ગોડાઉનમાં આવશે અને તરત આગળની પ્રક્રિયામાં આપી શકાશે.',
      ],
      exampleEn: 'Out of 50 pending pcs, worker returns 30 good today -> Pending drops to 20, Available Good rises by 30, and labour for 30 pcs is credited.',
      exampleGu: '50 બાકી પીસમાંથી આજે 30 સારા પીસ પરત આવે -> બાકી 20 રહેશે, ઉપલબ્ધ સ્ટોક 30 વધશે અને 30 પીસની મજૂરી જમા થશે.',
    ),
    HelpTopic(
      id: 'damaged-lost-shortage',
      order: 10,
      icon: Icons.report_problem_outlined,
      titleEn: 'Damaged, Lost & Shortage Explained',
      titleGu: 'ડેમેજ, ખોવાયેલ અને ઘટ વચ્ચેનો તફાવત',
      summaryEn: 'Understand how Damaged, Lost, and Shortage pieces behave differently in stock inventory and labour.',
      summaryGu: 'ડેમેજ, ખોવાયેલ અને ઘટ પીસની સ્ટોક અને મજૂરી પર અલગ-અલગ અસર કેવી રીતે થાય છે તે સમજો.',
      whenToUseEn:
          'When pieces returned are defective, missing, or fewer than issued.',
      whenToUseGu: 'જ્યારે પરત આવેલા પીસમાં ખામી હોય, ખોવાયા હોય અથવા ગણતરીમાં ઓછા નીકળે ત્યારે.',
      stepsEn: [
        'Damaged Returned: Physical piece came back with a defect. It moves into the Damaged Stock bucket and can later be repaired back to Good Stock via Repair Damaged.',
        'Lost: Physical piece is lost or misplaced and did not come back. It permanently reduces total good stock and never generates labour.',
        'Shortage: Count discrepancy / short quantity settled at reconciliation. Tracked separately from Lost in reports and never generates labour.',
        'All three require a written Reason for a clear workshop audit trail.',
      ],
      stepsGu: [
        'ડેમેજ પરત: ખામીવાળો પીસ પાછો આવ્યો છે. તે ડેમેજ સ્ટોકમાં જાય છે અને પછીથી "ડેમેજ રિપેર" દ્વારા સારા સ્ટોકમાં લાવી શકાય છે.',
        'ખોવાયેલ: પીસ ખોવાઈ ગયો છે અને પાછો નથી આવ્યો. તે કુલ સારો સ્ટોક કાયમ માટે ઘટાડે છે અને તેની મજૂરી ગણાતી નથી.',
        'ઘટ (શોર્ટેજ): ગણતરીના હિસાબ વખતે ખૂટતા પીસ. રિપોર્ટમાં ખોવાયેલથી અલગ દેખાય છે અને તેની મજૂરી ગણાતી નથી.',
        'આ ત્રણેય માટે ઓડિટ નોંધ તરીકે કારણ લખવું ફરજિયાત છે.',
      ],
      exampleEn: '50 issued -> 45 Good + 3 Damaged ("oil stain") + 1 Lost ("misplaced") + 1 Shortage ("count short"). Pending = 0, Damaged Bucket = 3.',
      exampleGu: '50 આપેલ -> 45 સારા + 3 ડેમેજ ("તેલનો ડાઘ") + 1 ખોવાયેલ + 1 ઘટ. બાકી = 0, ડેમેજ સ્ટોક = 3.',
    ),
    HelpTopic(
      id: 'worker-labour',
      order: 11,
      icon: Icons.work_outline_rounded,
      titleEn: 'Understanding Worker Labour',
      titleGu: 'કારીગર મજૂરી ગણતરી કેવી રીતે થાય છે',
      summaryEn: 'Learn how Billing Mode, locked issue rates, and anti-double-counting rules keep worker earnings accurate.',
      summaryGu: 'બિલિંગ પદ્ધતિ, લોક કરેલ ભાવ અને બેવડી ગણતરી રોકવાના નિયમોથી મજૂરી કેવી રીતે ચોક્કસ રહે છે તે સમજો.',
      whenToUseEn: 'When reviewing earned labour in Accounting or configuring billing preferences.',
      whenToUseGu: 'મજૂરી અને ચુકવણીમાં કમાયેલ મજૂરી તપાસતી વખતે અથવા બિલિંગ નિયમ બદલતી વખતે.',
      stepsEn: [
        'Default mode is Pay on Received Quantity: labour becomes payable when Good Returned pieces are recorded.',
        'Optional mode is Pay on Given Quantity: labour becomes payable immediately on Issue, and subsequent returns are marked "Info Only" so labour is never counted twice.',
        'Every Stock Issue locks its effective rate, billing mode, and damaged-inclusion flag permanently.',
        'Changing global settings later only affects future issues — historical records stay untouched.',
      ],
      stepsGu: [
        'ડિફોલ્ટ નિયમ "મળેલા જથ્થા પર મજૂરી" છે: જ્યારે સારો માલ પરત નોંધાય ત્યારે મજૂરી જમા થાય છે.',
        'વૈકલ્પિક નિયમ "આપેલા જથ્થા પર મજૂરી" છે: ઇશ્યૂ વખતે જ મજૂરી જમા થાય છે અને પરત માત્ર માહિતી માટે રહે છે જેથી બે વાર ગણતરી ન થાય.',
        'દરેક સ્ટોક ઇશ્યૂ વખતે તેનો ભાવ, બિલિંગ નિયમ અને ડેમેજ નિયમ કાયમ માટે લોક થઈ જાય છે.',
        'પછીથી મુખ્ય સેટિંગ બદલવાથી માત્ર નવા ઇશ્યૂ પર જ અસર થાય છે — જૂનો હિસાબ બદલાતો નથી.',
      ],
      exampleEn: '45 good pieces returned × ₹25.00 locked rate = ₹1,125.00 earned labour automatically added to the worker\'s ledger.',
      exampleGu: '45 સારા પીસ પરત × ₹25.00 લોક ભાવ = ₹1,125.00 કમાયેલ મજૂરી કારીગરની ખાતાવહીમાં આપમેળે જમા થાય છે.',
    ),
    HelpTopic(
      id: 'advances-and-payments',
      order: 12,
      icon: Icons.payments_outlined,
      titleEn: 'Recording Advances & Payments',
      titleGu: 'એડવાન્સ અને ચુકવણી નોંધવી',
      summaryEn: 'Track regular wage payouts, advance payments, and advance refunds cleanly with payment modes and references.',
      summaryGu: 'નિયમિત મજૂરી ચુકવણી, એડવાન્સ અને એડવાન્સ પરતને રોકડ/UPI/બેંક વિગત સાથે નોંધો.',
      whenToUseEn:
          'Whenever you give cash/UPI/bank payout or an advance to a worker.',
      whenToUseGu: 'જ્યારે પણ કારીગરને રોકડ, UPI કે બેંક દ્વારા પગાર અથવા એડવાન્સ આપો ત્યારે.',
      stepsEn: [
        'Open Labour & Payments from Dashboard or open a worker\'s profile and tap Record Payment / Advance.',
        'Select the Worker, Payment Type (Regular Payment, Advance Payment, or Advance Refund), and Amount (₹).',
        'Select Payment Mode (Cash, UPI, Bank Transfer, Cheque, Other) and optional Reference No.',
        'Tap Save. Advances are tracked separately and never mixed into earned labour.',
      ],
      stepsGu: [
        'ડેશબોર્ડમાંથી "મજૂરી અને ચુકવણી" ખોલો અથવા કારીગર પ્રોફાઇલમાંથી "ચુકવણી / એડવાન્સ નોંધો" ટેપ કરો.',
        'કારીગર, ચુકવણીનો પ્રકાર (નિયમિત, એડવાન્સ, અથવા એડવાન્સ પરત) અને રકમ (₹) પસંદ કરો.',
        'ચુકવણીની રીત (રોકડ, UPI, બેંક, ચેક) અને વૈકલ્પિક રેફરન્સ નંબર દાખલ કરો.',
        'સાચવો ટેપ કરો. એડવાન્સ અલગ ટ્રેક થાય છે અને ક્યારેય કમાયેલ મજૂરીમાં ભળતું નથી.',
      ],
      exampleEn: 'Pay ₹500 Advance via Cash before work starts -> Worker shows ₹500 Advance Credit until they earn ₹500+ in labour.',
      exampleGu: 'કામ શરૂ થાય તે પહેલાં ₹500 રોકડ એડવાન્સ આપો -> કારીગરના ખાતામાં ₹500 એડવાન્સ જમા દેખાશે.',
    ),
    HelpTopic(
      id: 'worker-ledger',
      order: 13,
      icon: Icons.receipt_long_outlined,
      titleEn: 'Understanding Worker Ledger Balances',
      titleGu: 'કારીગર ખાતાવહી અને બેલેન્સ સમજવું',
      summaryEn: 'Read running balances, Outstanding Payable vs Advance Credit, date filters, and audited adjustments.',
      summaryGu: 'ચાલુ બેલેન્સ, ચૂકવવાની બાકી વિરુદ્ધ એડવાન્સ જમા, તારીખ ફિલ્ટર અને સમાયોજન સમજો.',
      whenToUseEn: 'During weekly or monthly worker settlement and account reconciliation.',
      whenToUseGu: 'સાપ્તાહિક કે માસિક પગાર હિસાબ અને ખાતાવહી મેળવતી વખતે.',
      stepsEn: [
        'Open Labour & Payments and tap any worker card to open their full Worker Ledger.',
        'Positive Net Balance = Outstanding Payable (workshop owes the worker).',
        'Negative Net Balance = Advance Credit (worker has extra advance to adjust against future labour).',
        'Use From / To IST date filters to see Opening Balance and period transactions. Use Add Adjustment for audited bonuses or deductions.',
      ],
      stepsGu: [
        'મજૂરી અને ચુકવણી ખોલી કોઈપણ કારીગર પર ટેપ કરીને તેમની સંપૂર્ણ ખાતાવહી જુઓ.',
        'ધન (+) બેલેન્સ = ચૂકવવાની બાકી (કારખાનાએ કારીગરને ચૂકવવાના છે).',
        'ઋણ (-) બેલેન્સ = એડવાન્સ જમા (કારીગર પાસે એડવાન્સ રકમ જમા છે જે આગળના કામમાં મજરે મળશે).',
        'તારીખ ફિલ્ટરથી શરૂઆતનું બેલેન્સ અને તે સમયના વ્યવહારો જુઓ. બોનસ કે કપાત માટે "સમાયોજન ઉમેરો" વાપરો.',
      ],
      exampleEn: 'Earned ₹1,125 - Advance ₹500 - Regular Paid ₹400 = ₹225 Outstanding Payable.',
      exampleGu: 'કમાયેલ ₹1,125 - એડવાન્સ ₹500 - નિયમિત ચુકવણી ₹400 = ₹225 ચૂકવવાની બાકી.',
    ),
    HelpTopic(
      id: 'viewing-reports',
      order: 14,
      icon: Icons.analytics_outlined,
      titleEn: 'Viewing Business Reports',
      titleGu: 'વ્યવસાય રિપોર્ટ્સ જોવા',
      summaryEn: 'Inspect 10 live filterable reports covering stock, lots, workers, pending items, damaged/lost, labour, and payments.',
      summaryGu: 'સ્ટોક, લોટ્સ, કારીગર, બાકી માલ, ડેમેજ/ખોવાયેલ, મજૂરી અને ચુકવણીના ૧૦ લાઇવ રિપોર્ટ્સ જુઓ.',
      whenToUseEn: 'To review daily workshop progress, pending bottlenecks, or financial summaries.',
      whenToUseGu: 'રોજિંદી પ્રગતિ, બાકી કામ અથવા આર્થિક સારાંશ તપાસવા માટે.',
      stepsEn: [
        'Open Reports from the Dashboard Quick Actions or top navigation.',
        'Use the Search box and From / To IST Date pickers to narrow results.',
        'Switch between the 10 report chips: Stock Summary, Lot-Wise, Design/Colour, Worker Stock, Process Stock, Pending Stock, Damaged & Lost, Labour, Worker Accounts, and Payments.',
        'Tap any Pending Stock row to receive its return, or any Worker Account row to open their ledger.',
      ],
      stepsGu: [
        'ડેશબોર્ડ અથવા ઉપરના મેનુમાંથી "રિપોર્ટ્સ" ખોલો.',
        'શોધ બોક્સ અને તારીખ ફિલ્ટરનો ઉપયોગ કરીને જરૂરી ડેટા ફિલ્ટર કરો.',
        '૧૦ રિપોર્ટ ટેબ વચ્ચે સ્વિચ કરો: સ્ટોક સારાંશ, લોટ મુજબ, ડિઝાઇન/રંગ, કારીગર સ્ટોક, પ્રક્રિયા સ્ટોક, બાકી સ્ટોક, ડેમેજ/ખોવાયેલ, મજૂરી, કારીગર ખાતા અને ચુકવણી.',
        'બાકી સ્ટોક પર ટેપ કરીને સીધો માલ પરત લો અથવા કારીગર ખાતા પર ટેપ કરી ખાતાવહી ખોલો.',
      ],
      exampleEn: 'Filter by this week\'s IST dates -> Open "Pending Stock" to see which workers still hold unreturned pieces.',
      exampleGu: 'આ અઠવાડિયાની તારીખ પસંદ કરો -> "બાકી સ્ટોક" ખોલીને કયા કારીગર પાસે કેટલા પીસ બાકી છે તે તરત જુઓ.',
    ),
    HelpTopic(
      id: 'backup-and-restore',
      order: 15,
      icon: Icons.backup_outlined,
      titleEn: 'Creating & Restoring Backups',
      titleGu: 'બેકઅપ બનાવવો અને રિસ્ટોર કરવો',
      summaryEn: 'Protect your offline workshop records with full verified ZIP backups and raw SQLite exports.',
      summaryGu: 'તમારા ઓફલાઇન કારખાનાના ડેટાને સંપૂર્ણ ZIP બેકઅપ અને SQLite એક્સપોર્ટ દ્વારા સુરક્ષિત રાખો.',
      whenToUseEn: 'At least once a week, or before changing phones or making big updates.',
      whenToUseGu: 'ઓછામાં ઓછું અઠવાડિયે એકવાર અથવા ફોન બદલતા પહેલાં.',
      stepsEn: [
        'Open Settings -> Backup & Data Safety.',
        'Tap Create Full Backup (.zip) to package your SQLite database, all private lot photos, and an integrity manifest.',
        'Tap Share / Save File to copy the ZIP to Google Drive, external storage, or another safe device.',
        'To restore, tap Restore from Backup (.zip), pick your ZIP file, review the verified summary counts, and confirm overwrite. StitchFlow creates an automatic rollback safety copy before replacing data.',
      ],
      stepsGu: [
        'સેટિંગ્સ -> બેકઅપ અને ડેટા સુરક્ષા ખોલો.',
        '"સંપૂર્ણ બેકઅપ બનાવો (.zip)" પર ટેપ કરો જેથી SQLite ડેટાબેઝ, બધા લોટ ફોટા અને ચકાસણી મેનિફેસ્ટ એક ફાઇલમાં સુરક્ષિત બને.',
        '"ફાઇલ શેર / સેવ કરો" ટેપ કરીને ZIP ફાઇલને સુરક્ષિત જગ્યાએ કે ડ્રાઇવમાં સાચવો.',
        'રિસ્ટોર કરવા માટે ZIP ફાઇલ પસંદ કરો, ચકાસાયેલ વિગતો તપાસો અને ખાતરી કરો. ડેટા બદલતા પહેલાં સ્ટિચફ્લો આપમેળે સુરક્ષા કોપી બનાવે છે.',
      ],
      exampleEn: 'Every Saturday evening: Create Full Backup (.zip) -> Share to workshop Drive folder -> Peace of mind if phone is lost.',
      exampleGu: 'દર શનિવારે સાંજે: સંપૂર્ણ બેકઅપ (.zip) બનાવો -> સુરક્ષિત ફોલ્ડરમાં સાચવો -> ફોન બગડે તો પણ બધો હિસાબ સલામત.',
    ),
    HelpTopic(
      id: 'app-pin-and-biometrics',
      order: 16,
      icon: Icons.lock_outline_rounded,
      titleEn: 'App PIN & Fingerprint Unlock',
      titleGu: 'એપ પિન અને ફિંગરપ્રિન્ટ લોક',
      summaryEn: 'Protect workshop stock, rates, and karigar accounts with an optional local 4- or 6-digit PIN and fingerprint unlock.',
      summaryGu: 'કારખાનાનો સ્ટોક, ભાવ અને કારીગર હિસાબ સુરક્ષિત રાખવા માટે વૈકલ્પિક ૪ કે ૬ અંકનો ઓફલાઇન PIN અને ફિંગરપ્રિન્ટ લોક સેટ કરો.',
      whenToUseEn: 'When multiple family members or helpers may occasionally pick up your phone.',
      whenToUseGu: 'જ્યારે ઘરના સભ્યો કે અન્ય વ્યક્તિ ક્યારેક તમારો ફોન હાથમાં લેતા હોય ત્યારે.',
      stepsEn: [
        'Open Settings -> Security & App Lock and tap Enable App PIN.',
        'Choose a 4-digit (fast) or 6-digit numeric PIN and confirm it.',
        'Write down the 8-character offline Recovery Key on paper in your workshop diary, tick the confirmation box, and tap Activate App Lock.',
        'Optionally turn on Fingerprint / Biometric Unlock, choose your Auto-Lock Timeout (Immediate, 30s, 1m, 5m, 15m), and keep Screenshot & Recent Apps Protection ON.',
      ],
      stepsGu: [
        'સેટિંગ્સ -> સુરક્ષા અને એપ લોક ખોલી "App PIN ચાલુ કરો" પર ટેપ કરો.',
        '૪-અંકનો (ઝડપી) અથવા ૬-અંકનો PIN પસંદ કરો અને ફરીથી દાખલ કરીને ખાતરી કરો.',
        '૮-અક્ષરની ઓફલાઇન રિકવરી કી તમારી વર્કશોપ ડાયરીમાં લખી લો, ચેકબોક્સ ટિક કરો અને "એપ લોક ચાલુ કરો" ટેપ કરો.',
        'જરૂર મુજબ ફિંગરપ્રિન્ટ અનલોક, ઓટો-લોક સમય અને સ્ક્રીનશોટ સુરક્ષા ચાલુ રાખો.',
      ],
      exampleEn: 'Set 1-minute Auto-Lock + Fingerprint Unlock -> Tap the Lock icon in Dashboard top bar whenever handing your phone to someone.',
      exampleGu: '૧ મિનિટ ઓટો-લોક + ફિંગરપ્રિન્ટ ચાલુ રાખો -> કોઈને ફોન આપતા પહેલાં ડેશબોર્ડ ઉપરના લોક આઇકન પર ટેપ કરો.',
    ),
    HelpTopic(
      id: 'pin-recovery-and-lock-safety',
      order: 17,
      icon: Icons.vpn_key_outlined,
      titleEn: 'Recovery Key & App Lock Safety',
      titleGu: 'રિકવરી કી અને લોક સુરક્ષા',
      summaryEn: 'Reset a forgotten PIN offline using your written Recovery Key and understand what App Lock protects.',
      summaryGu: 'ભૂલાઈ ગયેલ PIN તમારી લખેલી રિકવરી કી વડે ઓફલાઇન રીસેટ કરો અને સુરક્ષા મર્યાદાઓ સમજો.',
      whenToUseEn: 'If you forget your App PIN, want a fresh Recovery Key, or need to restore a backup safely.',
      whenToUseGu: 'જો તમે App PIN ભૂલી જાઓ, નવી રિકવરી કી બનાવવી હોય અથવા સુરક્ષિત બેકઅપ રિસ્ટોર કરવો હોય.',
      stepsEn: [
        'On the Lock Screen, tap Forgot PIN? and enter your 8-character Recovery Key.',
        'Create and confirm a new PIN, then write down the newly generated Recovery Key.',
        'Note: App PIN protects against casual phone access and protects Backup Restore & Raw SQLite export with re-authentication.',
        'App PIN does not encrypt the local SQLite file on disk — always keep Android screen lock enabled and store backup ZIPs safely.',
      ],
      stepsGu: [
        'લોક સ્ક્રીન પર "PIN ભૂલી ગયા?" ટેપ કરો અને તમારી ૮-અક્ષરની રિકવરી કી દાખલ કરો.',
        'નવો PIN બનાવો અને નવી બનેલી રિકવરી કી ડાયરીમાં લખી લો.',
        'નોંધ: App PIN ફોન પર અનધિકૃત ઉપયોગ અટકાવે છે અને બેકઅપ રિસ્ટોર કે SQLite એક્સપોર્ટ પહેલાં ચકાસણી માંગે છે.',
        'App PIN ફોનની ડિસ્ક પર SQLite ફાઇલને એન્ક્રિપ્ટ કરતું નથી — હંમેશા ફોનનો સ્ક્રીન લોક ચાલુ રાખો.',
      ],
      exampleEn: 'Forgot PIN? Tap Forgot PIN? -> Enter ABCD-2345 from workshop diary -> Set a fresh PIN without losing any lots or worker balances.',
      exampleGu: 'PIN ભૂલી ગયા? "PIN ભૂલી ગયા?" ટેપ કરો -> ડાયરીમાંથી રિકવરી કી નાખો -> કોઈપણ ડેટા ગુમાવ્યા વિના નવો PIN સેટ કરો.',
    ),
    HelpTopic(
      id: 'advanced-reports-and-export',
      order: 18,
      icon: Icons.ios_share_rounded,
      titleEn: 'Advanced Reports, PDF & Excel Export',
      titleGu: 'એડવાન્સ રિપોર્ટ્સ, PDF અને એક્સેલ એક્સપોર્ટ',
      summaryEn: 'Filter 6 unified report categories by IST dates, worker, process, or lot, and export Gujarati-safe PDF, Excel (.xlsx), or CSV.',
      summaryGu: '૬ રિપોર્ટ વિભાગોને તારીખ, કારીગર, પ્રક્રિયા કે લોટ મુજબ ફિલ્ટર કરો અને ગુજરાતીમાં PDF, Excel (.xlsx) કે CSV એક્સપોર્ટ કરો.',
      whenToUseEn: 'For weekly worker settlements, monthly workshop reviews, or sharing reports with your accountant/partner.',
      whenToUseGu: 'સાપ્તાહિક હિસાબ, માસિક સમીક્ષા અથવા એકાઉન્ટન્ટ/ભાગીદાર સાથે રિપોર્ટ શેર કરવા માટે.',
      stepsEn: [
        'Open Reports and tap any IST Date Preset (Today, Yesterday, This Week, This Month, Prev. Month, All Time).',
        'Tap Filters to narrow by Worker, Process, Lot, Design, or Colour.',
        'Switch across the 6 categories: Daily Workshop, Worker Performance, Process Performance, Inventory, Labour & Financial, and Business Insights.',
        'Tap the Export / Print icon in the top bar to Print / Save as PDF (with full Gujarati font support), share an Excel (.xlsx) workbook, or export UTF-8 CSV.',
      ],
      stepsGu: [
        'રિપોર્ટ્સ ખોલો અને સમયગાળો પસંદ કરો (આજે, ગઈકાલે, આ અઠવાડિયું, આ મહિનો, ગયા મહિના, બધો સમય).',
        'કારીગર, પ્રક્રિયા, લોટ, ડિઝાઇન કે રંગ મુજબ ફિલ્ટર કરવા માટે "ફિલ્ટર" પર ટેપ કરો.',
        '૬ વિભાગો જુઓ: દૈનિક વર્કશોપ, કારીગર કામગીરી, પ્રક્રિયા કામગીરી, સ્ટોક/ઇન્વેન્ટરી, મજૂરી અને હિસાબ, અને વ્યવસાયિક વિશ્લેષણ.',
        'ઉપરના "એક્સપોર્ટ / પ્રિન્ટ" બટન પર ટેપ કરીને ગુજરાતી ફોન્ટ સાથે PDF સેવ કરો, Excel (.xlsx) શેર કરો અથવા CSV બનાવો.',
      ],
      exampleEn: 'Select "This Month" -> Open "Business Insights" to inspect Process Bottlenecks -> Tap Export / Print -> Full Excel Workbook (.xlsx).',
      exampleGu: '"આ મહિનો" પસંદ કરો -> "વ્યવસાયિક વિશ્લેષણ" માં બાકી અવરોધો જુઓ -> "એક્સપોર્ટ / પ્રિન્ટ" -> સંપૂર્ણ એક્સેલ વર્કબુક (.xlsx).',
    ),
    HelpTopic(
      id: 'local-reminders-notifications',
      order: 19,
      icon: Icons.notifications_outlined,
      titleEn: 'Local Reminders & Android Battery Settings',
      titleGu: 'ઓફલાઇન યાદ અપાવણી અને બેટરી સેટિંગ્સ',
      summaryEn: 'Configure 100% offline Android reminders for pending returns, weekly settlements, evening recap, and backups.',
      summaryGu: 'બાકી કામ, સાપ્તાહિક હિસાબ, સાંજના સારાંશ અને બેકઅપ માટે ૧૦૦% ઓફલાઇન એન્ડ્રોઇડ યાદ અપાવણી સેટ કરો.',
      whenToUseEn: 'To receive timely local workshop reminders without internet or Firebase.',
      whenToUseGu:
          'ઇન્ટરનેટ કે ફાયરબેઝ વિના સમયસર વર્કશોપની યાદ અપાવણી મેળવવા માટે.',
      stepsEn: [
        'Open Settings -> Notifications & Reminders and tap Allow Notifications.',
        'Customize thresholds and IST times for Pending Work, Worker Settlement, Daily Summary, Backup Reminder, and Important Alerts.',
        'Reminders cancel automatically as soon as pending work or worker balances are cleared.',
        'On OPPO (ColorOS), Xiaomi, Vivo, or Samsung phones, if reminders arrive late after a reboot, open Android Phone Settings -> Apps -> StitchFlow -> Battery and allow background activity.',
      ],
      stepsGu: [
        'સેટિંગ્સ -> નોટિફિકેશન અને યાદ અપાવણી ખોલી "નોટિફિકેશન ચાલુ કરો" પર ટેપ કરો.',
        'બાકી કામ, કારીગર હિસાબ, દૈનિક સારાંશ, બેકઅપ અને ચેતવણી માટે સમય અને મર્યાદા પસંદ કરો.',
        'જેવું બાકી કામ કે હિસાબ પૂર્ણ થાય, તે યાદ અપાવણી આપમેળે રદ થઈ જાય છે.',
        'OPPO (ColorOS), Xiaomi, Vivo અથવા Samsung ફોનમાં રીસ્ટાર્ટ પછી નોટિફિકેશન મોડા આવે તો Phone Settings -> Apps -> StitchFlow -> Battery માં બેકગ્રાઉન્ડ પ્રવૃત્તિ ચાલુ કરો.',
      ],
      exampleEn: 'Set Pending Work reminder to 3 days @ 10:00 AM IST -> If all karigar returns are settled before 10:00 AM, StitchFlow cancels the alert automatically.',
      exampleGu: 'બાકી કામની યાદ અપાવણી ૩ દિવસ / સવારે ૧૦:૦૦ વાગ્યે સેટ કરો -> ૧૦ વાગ્યા પહેલાં બધો માલ પરત આવી જાય તો એલર્ટ આપમેળે રદ થશે.',
    ),
  ];

  static HelpTopic? byId(String id) {
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }
}
