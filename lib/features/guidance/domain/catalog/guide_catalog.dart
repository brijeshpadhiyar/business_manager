import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';

/// Complete bilingual (English & Gujarati) interactive training catalog:
/// - 9 End-to-End Workshop Training Chapters (ordered by real garment flow)
/// - Per-Screen button-upper spotlight tours for every core screen
/// - Action links & "What To Do Next" transitions for all 19 Help Topics
abstract final class GuideCatalog {
  /// All 9 end-to-end training chapters in exact workshop execution order.
  static const List<GuideChapter> chapters = <GuideChapter>[
    // ── Chapter 1: Dashboard, Navigation & Quick Actions ───────────────────
    GuideChapter(
      id: 'dashboard-overview',
      order: 1,
      screenId: GuideScreenId.home,
      routePath: '/',
      primaryTabIndex: 0,
      iconKey: 'dashboard',
      titleEn: 'Dashboard & Everyday Actions',
      titleGu: 'ડેશબોર્ડ અને રોજિંદા કાર્યો',
      summaryEn:
          'Learn the home screen layout, 1-tap workshop quick actions, search, and where to replay guidance anytime.',
      summaryGu:
          'હોમ સ્ક્રીન, ૧-ટેપ વર્કશોપ ઝડપી બટનો, શોધ અને ગમે ત્યારે માર્ગદર્શન કેવી રીતે ફરી શરૂ કરવું તે સમજો.',
      nextStepLabelEn: 'Next: Set up your Workshop Name & Billing Mode',
      nextStepLabelGu: 'આગળ: તમારા કારખાનાનું નામ અને મજૂરી નિયમ સેટ કરો',
      relatedHelpTopicIds: ['getting-started'],
      steps: [
        GuideStep(
          id: 'ch1_guide_btn',
          chapterId: 'dashboard-overview',
          screenId: GuideScreenId.home,
          routePath: '/',
          primaryTabIndex: 0,
          targetId: GuideTargetId.appBarGuide,
          titleEn: 'Guide Button (?) — Help Anytime',
          titleGu: 'માર્ગદર્શન બટન (?) — ગમે ત્યારે મદદ',
          actionDescriptionEn:
              'Tap this button on any screen to highlight what every button does, turn Voice ON/OFF, or open the full User Guide.',
          actionDescriptionGu:
              'કોઈપણ સ્ક્રીન પર આ બટન દબાવો અને જાણો કે દરેક બટન શું કામ કરે છે, અવાજ ચાલુ/બંધ કરો અથવા સંપૂર્ણ યુઝર ગાઇડ ખોલો.',
          nextActionHintEn:
              'Next: Tap Next to see how Quick Actions speed up daily work.',
          nextActionHintGu:
              'આગળ: રોજિંદા કામ ઝડપી બનાવતા બટનો જોવા માટે "આગળ" દબાવો.',
          speechEn:
              'Welcome to Business Manager. This Guide button is always at the top. Tap it on any screen to hear what every button does.',
          speechGu:
              'બિઝનેસ મેનેજરમાં તમારું સ્વાગત છે. આ માર્ગદર્શન બટન હંમેશા ઉપર રહે છે. કોઈપણ સ્ક્રીન પર દરેક બટનનું કામ જાણવા આ બટન દબાવો.',
        ),
        GuideStep(
          id: 'ch1_search_btn',
          chapterId: 'dashboard-overview',
          screenId: GuideScreenId.home,
          routePath: '/',
          primaryTabIndex: 0,
          targetId: GuideTargetId.appBarSearch,
          titleEn: 'Global Search',
          titleGu: 'ઝડપી શોધ (સર્ચ)',
          actionDescriptionEn:
              'Instantly find any Lot number, Worker name, Process, or jump directly to Issue Stock, Receive Return, or Payment.',
          actionDescriptionGu:
              'કોઈપણ લોટ નંબર, કારીગરનું નામ, પ્રક્રિયા તરત શોધો અથવા સીધા સ્ટોક આપો, પરત લો કે ચુકવણી ખોલો.',
          nextActionHintEn:
              'Next: Explore the 6 everyday Quick Action tiles right below.',
          nextActionHintGu: 'આગળ: નીચે આપેલા ૬ રોજિંદા ઝડપી બટનો સમજો.',
          speechEn:
              'Use Global Search to find any lot, worker, or process in one second.',
          speechGu:
              'ઝડપી શોધ વડે તમે કોઈપણ લોટ, કારીગર કે પ્રક્રિયા તરત જ શોધી શકો છો.',
        ),
        GuideStep(
          id: 'ch1_quick_issue',
          chapterId: 'dashboard-overview',
          screenId: GuideScreenId.home,
          routePath: '/',
          primaryTabIndex: 0,
          targetId: GuideTargetId.dashQuickIssue,
          titleEn: 'Issue Stock Button',
          titleGu: 'સ્ટોક આપો (ઇશ્યૂ) બટન',
          actionDescriptionEn:
              'Gives available in-house pieces to a worker for any process and automatically locks the piece rate.',
          actionDescriptionGu:
              'ગોડાઉનમાં ઉપલબ્ધ સારા પીસ કોઈપણ પ્રક્રિયા માટે કારીગરને આપે છે અને પીસ દીઠ ભાવ આપમેળે લોક કરે છે.',
          nextActionHintEn:
              'Next: Look at Receive Return right beside it.',
          nextActionHintGu: 'આગળ: તેની બાજુમાં આવેલ "માલ પરત લો" બટન જુઓ.',
          speechEn:
              'Issue Stock lets you give good pieces to a worker and automatically locks their rate for that date.',
          speechGu:
              'સ્ટોક આપો બટનથી તમે કારીગરને કામ માટે સારા પીસ આપી શકો છો અને તે તારીખનો ભાવ આપમેળે લોક થઈ જાય છે.',
        ),
        GuideStep(
          id: 'ch1_quick_receive',
          chapterId: 'dashboard-overview',
          screenId: GuideScreenId.home,
          routePath: '/',
          primaryTabIndex: 0,
          targetId: GuideTargetId.dashQuickReceive,
          titleEn: 'Receive Work / Return Button',
          titleGu: 'માલ પરત લો બટન',
          actionDescriptionEn:
              'Records Good, Damaged, Lost, or Shortage pieces brought back by a worker and updates earned labour automatically.',
          actionDescriptionGu:
              'કારીગર પાસેથી પરત આવેલ સારા, ડેમેજ, ખોવાયેલ કે ઘટ પીસ નોંધે છે અને કમાયેલ મજૂરી આપમેળે ઉમેરે છે.',
          nextActionHintEn:
              'Next: Check how worker payments and new lots start from here.',
          nextActionHintGu:
              'આગળ: કારીગર ચુકવણી અને નવા લોટના ઝડપી બટનો જુઓ.',
          speechEn:
              'Receive Work records returned good, damaged, or lost pieces and calculates worker labour automatically.',
          speechGu:
              'માલ પરત લો બટનથી કારીગર પાસેથી આવેલ સારા, ડેમેજ કે ખોવાયેલ પીસ નોંધાય છે અને મજૂરી આપમેળે ગણાય છે.',
        ),
        GuideStep(
          id: 'ch1_quick_payment',
          chapterId: 'dashboard-overview',
          screenId: GuideScreenId.home,
          routePath: '/',
          primaryTabIndex: 0,
          targetId: GuideTargetId.dashQuickPayment,
          titleEn: 'Record Payment / Advance',
          titleGu: 'ચુકવણી / એડવાન્સ નોંધો',
          actionDescriptionEn:
              'Logs cash, UPI, or bank wage payouts and keeps Advance Credit separate from Earned Labour.',
          actionDescriptionGu:
              'રોકડ, UPI કે બેંક દ્વારા પગાર અથવા એડવાન્સ નોંધે છે અને એડવાન્સ જમા રકમને મજૂરીથી અલગ રાખે છે.',
          nextActionHintEn:
              'Next: See the bottom tabs to move across Lots, Stock, Workers, and Settings.',
          nextActionHintGu:
              'આગળ: લોટ્સ, સ્ટોક, કારીગરો અને સેટિંગ્સ વચ્ચે જવા માટે મુખ્ય મેનુ જુઓ.',
          speechEn:
              'Record Payment saves worker wages or advances via cash, UPI, or bank transfer.',
          speechGu:
              'ચુકવણી નોંધો બટનથી કારીગરને આપેલ પગાર કે એડવાન્સ રોકડ, UPI કે બેંક વિગત સાથે સાચવી શકાય છે.',
        ),
        GuideStep(
          id: 'ch1_today_kpis',
          chapterId: 'dashboard-overview',
          screenId: GuideScreenId.home,
          routePath: '/',
          primaryTabIndex: 0,
          targetId: GuideTargetId.dashTodayKpis,
          titleEn: 'Live Daily Activity & Stock Health',
          titleGu: 'આજની કામગીરી અને સ્ટોક સારાંશ',
          actionDescriptionEn:
              'Shows today\'s issued pieces, returned good pieces, earned labour, and payments. Tap any tile to drill into full details.',
          actionDescriptionGu:
              'આજે આપેલા પીસ, પરત આવેલા પીસ, મજૂરી અને ચુકવણી લાઇવ બતાવે છે. કોઈપણ કાર્ડ પર ટેપ કરીને સંપૂર્ણ વિગત જુઓ.',
          nextActionHintEn:
              'Next Chapter: We will open Settings to configure your Business Profile.',
          nextActionHintGu:
              'આગળનું પ્રકરણ: હવે આપણે સેટિંગ્સમાં જઈને તમારા કારખાનાની પ્રોફાઇલ સમજીશું.',
          speechEn:
              'These live tiles show today\'s workshop output and money. Tap any card anytime to inspect details. Let us move to Workshop Setup next.',
          speechGu:
              'આ લાઇવ કાર્ડ આજનો સ્ટોક અને હિસાબ બતાવે છે. કોઈપણ કાર્ડ પર ટેપ કરીને વિગતો જોઈ શકાય છે. હવે આગળ કારખાનાનું સેટઅપ જોઈએ.',
        ),
      ],
    ),

    // ── Chapter 2: Workshop Profile & Billing Rules ────────────────────────
    GuideChapter(
      id: 'business-setup',
      order: 2,
      screenId: GuideScreenId.settings,
      routePath: '/settings',
      primaryTabIndex: 4,
      iconKey: 'business',
      titleEn: 'Workshop Profile & Billing Mode',
      titleGu: 'કારખાનાની પ્રોફાઇલ અને મજૂરી નિયમ',
      summaryEn:
          'Configure your workshop name in English & Gujarati, theme/language, and whether labour is paid on Received or Given quantity.',
      summaryGu:
          'તમારા કારખાનાનું નામ (અંગ્રેજી અને ગુજરાતી), ભાષા/થીમ અને મજૂરી ગણતરીનો મુખ્ય નિયમ સેટ કરો.',
      nextStepLabelEn: 'Next: Create your custom Production Processes',
      nextStepLabelGu: 'આગળ: તમારી પ્રોડક્શન પ્રક્રિયાઓ બનાવો',
      relatedHelpTopicIds: ['getting-started', 'worker-labour'],
      steps: [
        GuideStep(
          id: 'ch2_business_profile',
          chapterId: 'business-setup',
          screenId: GuideScreenId.settings,
          routePath: '/settings',
          primaryTabIndex: 4,
          targetId: GuideTargetId.settingsBusinessProfileTile,
          isInteractiveAction: true,
          titleEn: 'Business Profile',
          titleGu: 'બિઝનેસ પ્રોફાઇલ',
          actionDescriptionEn:
              'Set your workshop name (English & Gujarati), owner name, phone, and address that appear on printed slips and PDF reports.',
          actionDescriptionGu:
              'તમારા કારખાનાનું નામ (અંગ્રેજી અને ગુજરાતી), માલિકનું નામ, ફોન અને સરનામું સેટ કરો જે સ્લિપ અને PDF રિપોર્ટમાં છપાય છે.',
          nextActionHintEn:
              'Do this first: Tap Business Profile to enter your shop name, or tap Next to continue the tour.',
          nextActionHintGu:
              'પહેલા આ કરો: કારખાનાનું નામ ભરવા "બિઝનેસ પ્રોફાઇલ" ખોલો, અથવા ગાઇડ આગળ વધારવા "આગળ" દબાવો.',
          speechEn:
              'Step one of workshop setup is Business Profile. Enter your workshop name here so it appears on every slip and report.',
          speechGu:
              'સેટઅપનું પહેલું પગલું બિઝનેસ પ્રોફાઇલ છે. અહીં તમારા કારખાનાનું નામ લખો જેથી દરેક સ્લિપ અને રિપોર્ટમાં દેખાય.',
        ),
        GuideStep(
          id: 'ch2_stock_labour',
          chapterId: 'business-setup',
          screenId: GuideScreenId.settings,
          routePath: '/settings',
          primaryTabIndex: 4,
          targetId: GuideTargetId.settingsStockLabourTile,
          titleEn: 'Stock & Labour Rules',
          titleGu: 'સ્ટોક અને મજૂરી નિયમો',
          actionDescriptionEn:
              'Choose default labour billing: Pay on Received Good Pieces (recommended) or Pay on Given Pieces, plus damaged-piece labour policy.',
          actionDescriptionGu:
              'મજૂરીનો ડિફોલ્ટ નિયમ પસંદ કરો: મળેલા સારા પીસ પર મજૂરી (ભલામણ કરેલ) અથવા આપેલા પીસ પર મજૂરી.',
          nextActionHintEn:
              'Next Chapter: Create your Production Processes (like Cutting, Stitching, Press).',
          nextActionHintGu:
              'આગળનું પ્રકરણ: હવે તમારી પ્રોડક્શન પ્રક્રિયાઓ (કટિંગ, સ્ટિચિંગ, પ્રેસ) બનાવીએ.',
          speechEn:
              'Stock and Labour Settings control whether workers earn labour when good pieces return or when stock is given. Next, let us open Production Processes.',
          speechGu:
              'સ્ટોક અને મજૂરી સેટિંગ્સમાં નક્કી થાય છે કે મજૂરી સારો માલ પરત આવે ત્યારે ગણવી કે આપતી વખતે. હવે આગળ પ્રક્રિયાઓ જોઈએ.',
        ),
      ],
    ),

    // ── Chapter 3: Production Processes ────────────────────────────────────
    GuideChapter(
      id: 'processes-setup',
      order: 3,
      screenId: GuideScreenId.processes,
      routePath: '/processes',
      iconKey: 'process',
      titleEn: 'Creating Production Processes',
      titleGu: 'પ્રોડક્શન પ્રક્રિયાઓ બનાવવી',
      summaryEn:
          'Define any custom garment stages (Cutting, Stitching, Embroidery, Press, Packing) with zero fixed order.',
      summaryGu:
          'કોઈપણ નક્કી ક્રમ વગર તમારા કારખાનાની પ્રક્રિયાઓ (કટિંગ, સ્ટિચિંગ, એમ્બ્રોઇડરી, પ્રેસ) બનાવો.',
      nextStepLabelEn: 'Next: Add Workers and set their Per-Piece Rates',
      nextStepLabelGu: 'આગળ: કારીગરો ઉમેરો અને તેમના પીસ દીઠ ભાવ સેટ કરો',
      relatedHelpTopicIds: ['creating-processes'],
      steps: [
        GuideStep(
          id: 'ch3_new_process',
          chapterId: 'processes-setup',
          screenId: GuideScreenId.processes,
          routePath: '/processes',
          targetId: GuideTargetId.processNewAction,
          isInteractiveAction: true,
          titleEn: 'New Process Button',
          titleGu: 'નવી પ્રક્રિયા બટન',
          actionDescriptionEn:
              'Creates a custom workshop stage (e.g., Cutting, Stitching, Overlock, Press). You can also set a default rate and process-specific labour rule.',
          actionDescriptionGu:
              'તમારા કારખાનાની નવી પ્રક્રિયા બનાવે છે (દા.ત. કટિંગ, સ્ટિચિંગ, પ્રેસ). તમે ડિફોલ્ટ ભાવ અને અલગ મજૂરી નિયમ પણ રાખી શકો છો.',
          nextActionHintEn:
              'Action: Tap New Process to add your stages, then tap Next Chapter to add Workers.',
          nextActionHintGu:
              'કાર્ય: નવી પ્રક્રિયા ઉમેરવા આ બટન દબાવો, પછી કારીગરો ઉમેરવા "આગળ" દબાવો.',
          speechEn:
              'Here you create your workshop processes such as Cutting, Stitching, or Press. Tap New Process to add them anytime. Next, we will add your workers.',
          speechGu:
              'અહીં તમે કટિંગ, સ્ટિચિંગ કે પ્રેસ જેવી તમારી પ્રક્રિયાઓ બનાવી શકો છો. નવી પ્રક્રિયા ઉમેરવા આ બટન દબાવો. હવે આગળ કારીગરો જોઈએ.',
        ),
      ],
    ),

    // ── Chapter 4: Workers, Assignments & Per-Piece Rates ──────────────────
    GuideChapter(
      id: 'workers-and-rates',
      order: 4,
      screenId: GuideScreenId.workers,
      routePath: '/workers',
      primaryTabIndex: 3,
      iconKey: 'workers',
      titleEn: 'Workers, Assignments & Piece Rates',
      titleGu: 'કારીગરો, સોંપણી અને પીસ દીઠ ભાવ',
      summaryEn:
          'Add each karigar, link them to the processes they handle, and record effective-dated per-piece rates.',
      summaryGu:
          'દરેક કારીગરને ઉમેરો, તેમને પ્રક્રિયા સોંપો અને તારીખ મુજબ પીસ દીઠ ભાવ સેટ કરો.',
      nextStepLabelEn: 'Next: Create your First Lot with Designs & Colours',
      nextStepLabelGu: 'આગળ: તમારો પહેલો લોટ, ડિઝાઇન અને રંગ ઉમેરો',
      relatedHelpTopicIds: [
        'adding-workers',
        'assigning-workers',
        'setting-worker-rates',
      ],
      steps: [
        GuideStep(
          id: 'ch4_new_worker',
          chapterId: 'workers-and-rates',
          screenId: GuideScreenId.workers,
          routePath: '/workers',
          primaryTabIndex: 3,
          targetId: GuideTargetId.workerNewAction,
          isInteractiveAction: true,
          titleEn: 'New Worker Button',
          titleGu: 'નવો કારીગર બટન',
          actionDescriptionEn:
              'Adds a tailor, cutter, presser, or job-worker with phone and notes. After saving, open the worker to assign Processes and set per-piece Rates.',
          actionDescriptionGu:
              'નવા કારીગરનું નામ, ફોન અને નોંધ ઉમેરે છે. સાચવ્યા પછી કારીગર ખોલીને પ્રક્રિયા સોંપણી અને પીસ દીઠ ભાવ સેટ કરો.',
          nextActionHintEn:
              'Action: Tap New Worker to add a karigar, then open their profile to Assign Process & Add Rate. Tap Next for Lots.',
          nextActionHintGu:
              'કાર્ય: કારીગર ઉમેરવા આ બટન દબાવો, પછી તેમની પ્રોફાઇલમાં પ્રક્રિયા અને ભાવ સેટ કરો. હવે લોટ્સ જોવા "આગળ" દબાવો.',
          speechEn:
              'Tap New Worker to add a karigar. Once saved, open any worker to assign their processes and set historical per-piece rates. Next, let us create a Lot.',
          speechGu:
              'નવો કારીગર ઉમેરવા આ બટન દબાવો. સાચવ્યા પછી કારીગરની પ્રોફાઇલ ખોલી પ્રક્રિયા સોંપો અને પીસ દીઠ ભાવ સેટ કરો. હવે આગળ લોટ બનાવતા શીખીએ.',
        ),
      ],
    ),

    // ── Chapter 5: Lots, Designs & Colours ─────────────────────────────────
    GuideChapter(
      id: 'lots-designs-colours',
      order: 5,
      screenId: GuideScreenId.lots,
      routePath: '/lots',
      primaryTabIndex: 1,
      iconKey: 'lot',
      titleEn: 'Lots, Designs & Colours (Opening Stock)',
      titleGu: 'લોટ, ડિઝાઇન અને રંગ (શરૂઆતનો સ્ટોક)',
      summaryEn:
          'Create each fabric batch as a Lot, add Designs inside it, and record Colours with initial good pieces and piece prices.',
      summaryGu:
          'દરેક નવા કાપડ બેચનો લોટ બનાવો, તેની અંદર ડિઝાઇન અને રંગનો શરૂઆતનો જથ્થો તથા ભાવ નોંધો.',
      nextStepLabelEn: 'Next: Issue Good Stock from a Lot to a Worker',
      nextStepLabelGu: 'આગળ: લોટમાંથી કારીગરને સ્ટોક આપો (ઇશ્યૂ)',
      relatedHelpTopicIds: ['creating-a-lot', 'designs-and-colours'],
      steps: [
        GuideStep(
          id: 'ch5_new_lot',
          chapterId: 'lots-designs-colours',
          screenId: GuideScreenId.lots,
          routePath: '/lots',
          primaryTabIndex: 1,
          targetId: GuideTargetId.lotNewAction,
          isInteractiveAction: true,
          titleEn: 'New Lot Button',
          titleGu: 'નવો લોટ બટન',
          actionDescriptionEn:
              'Creates a new garment batch with a unique Lot Number, IST date, and optional fabric photos. Inside the Lot, add Designs & Colours to put pieces into Available Good Stock.',
          actionDescriptionGu:
              'અલગ લોટ નંબર, તારીખ અને ફોટા સાથે નવો લોટ બનાવે છે. લોટની અંદર ડિઝાઇન અને રંગ ઉમેરતા જ પીસ ઉપલબ્ધ સારા સ્ટોકમાં આવી જાય છે.',
          nextActionHintEn:
              'Action: Tap New Lot -> Save -> Add Design -> Add Colour (Qty). Tap Next to learn Stock Issue.',
          nextActionHintGu:
              'કાર્ય: નવો લોટ બનાવો -> સાચવો -> ડિઝાઇન ઉમેરો -> રંગ અને જથ્થો ઉમેરો. સ્ટોક આપતા શીખવા "આગળ" દબાવો.',
          speechEn:
              'Tap New Lot whenever a new batch arrives. After saving, open the lot to add Designs and Colours with initial quantities so they become ready for issue.',
          speechGu:
              'જ્યારે નવો માલ આવે ત્યારે નવો લોટ બટન દબાવો. સાચવ્યા પછી લોટમાં ડિઝાઇન અને રંગનો જથ્થો ઉમેરો જેથી તે સ્ટોક આપવા માટે તૈયાર થઈ જાય.',
        ),
      ],
    ),

    // ── Chapter 6: Issuing Stock to Workers ────────────────────────────────
    GuideChapter(
      id: 'issue-stock',
      order: 6,
      screenId: GuideScreenId.stock,
      routePath: '/stock',
      primaryTabIndex: 2,
      iconKey: 'stockIssue',
      titleEn: 'Issuing Stock to Workers',
      titleGu: 'કારીગરને સ્ટોક આપવો (ઇશ્યૂ)',
      summaryEn:
          'Issue available in-house good stock to an assigned worker in 4 guided steps with automatic rate locking.',
      summaryGu:
          'ઉપલબ્ધ સારા સ્ટોકમાંથી સોંપેલા કારીગરને આપમેળે ભાવ લોક સાથે માલ આપો.',
      nextStepLabelEn: 'Next: Receive Returned Stock (Good, Damaged, Lost)',
      nextStepLabelGu: 'આગળ: કારીગર પાસેથી માલ પરત લો (સારો, ડેમેજ, ખોવાયેલ)',
      relatedHelpTopicIds: ['issuing-stock'],
      steps: [
        GuideStep(
          id: 'ch6_issue_btn',
          chapterId: 'issue-stock',
          screenId: GuideScreenId.stock,
          routePath: '/stock',
          primaryTabIndex: 2,
          targetId: GuideTargetId.stockIssueAction,
          isInteractiveAction: true,
          titleEn: 'Issue Stock Button',
          titleGu: 'સ્ટોક આપો બટન',
          actionDescriptionEn:
              'Opens the 4-step Stock Issue flow: Pick Lot/Colour -> Pick Process & Eligible Worker -> Enter Quantity -> Confirm. Effective piece rate and billing rule lock automatically.',
          actionDescriptionGu:
              '૪ સ્ટેપમાં સ્ટોક આપવાનું ખોલે છે: લોટ/રંગ પસંદ કરો -> પ્રક્રિયા અને કારીગર પસંદ કરો -> પીસ લખો -> ખાતરી કરો. ભાવ અને નિયમ આપમેળે લોક થાય છે.',
          nextActionHintEn:
              'Action: Tap Issue Stock whenever pieces leave your table. Tap Next to see Receive Return.',
          nextActionHintGu:
              'કાર્ય: કારીગરને માલ આપવા આ બટન વાપરો. હવે માલ પરત લેતા શીખવા "આગળ" દબાવો.',
          speechEn:
              'Tap Issue Stock to hand pieces to a worker. Pick the colour, process, worker, and quantity. StitchFlow locks the exact piece rate automatically.',
          speechGu:
              'કારીગરને પીસ આપવા સ્ટોક આપો બટન દબાવો. રંગ, પ્રક્રિયા, કારીગર અને પીસ પસંદ કરો. તે તારીખનો ભાવ આપમેળે લોક થઈ જશે.',
        ),
      ],
    ),

    // ── Chapter 7: Receiving Returns & Handling Damaged/Lost ───────────────
    GuideChapter(
      id: 'receive-returns',
      order: 7,
      screenId: GuideScreenId.stock,
      routePath: '/stock',
      primaryTabIndex: 2,
      iconKey: 'receiveReturn',
      titleEn: 'Receiving Returns & Damaged Stock',
      titleGu: 'માલ પરત લેવો અને ડેમેજ સ્ટોક',
      summaryEn:
          'Record full or partial returns, separate Damaged/Lost/Shortage safely, and repair salvaged pieces back to Good Stock.',
      summaryGu:
          'પૂરો કે આંશિક માલ પરત લો, ડેમેજ/ખોવાયેલ/ઘટ અલગ નોંધો અને રિપેર થયેલ ડેમેજ પીસ ફરી સારા સ્ટોકમાં લાવો.',
      nextStepLabelEn: 'Next: Record Worker Payments, Advances & View Ledger',
      nextStepLabelGu: 'આગળ: કારીગર ચુકવણી, એડવાન્સ અને ખાતાવહી જુઓ',
      relatedHelpTopicIds: ['receiving-returns', 'damaged-lost-shortage'],
      steps: [
        GuideStep(
          id: 'ch7_receive_btn',
          chapterId: 'receive-returns',
          screenId: GuideScreenId.stock,
          routePath: '/stock',
          primaryTabIndex: 2,
          targetId: GuideTargetId.stockReceiveAction,
          isInteractiveAction: true,
          titleEn: 'Receive Return Button',
          titleGu: 'માલ પરત લો બટન',
          actionDescriptionEn:
              'Pick any open pending issue and enter Good Returned (or tap All Good), plus any Damaged, Lost, or Shortage pieces with mandatory reason.',
          actionDescriptionGu:
              'બાકી ઇશ્યૂ પસંદ કરો અને પરત આવેલા સારા પીસ (અથવા "બધો સારો") તથા ડેમેજ, ખોવાયેલ કે ઘટ પીસ કારણ સાથે નોંધો.',
          nextActionHintEn:
              'Next: See the Repair Damaged button and Stock Tabs right below.',
          nextActionHintGu:
              'આગળ: ડેમેજ રિપેર બટન અને સ્ટોક વિભાગો જુઓ.',
          speechEn:
              'When a worker brings pieces back, tap Receive Return. Only Good pieces return to available stock and earn labour by default.',
          speechGu:
              'કારીગર માલ પરત લાવે ત્યારે માલ પરત લો બટન દબાવો. માત્ર સારા પીસ પાછા ગોડાઉનમાં આવે છે અને તેની મજૂરી જમા થાય છે.',
        ),
        GuideStep(
          id: 'ch7_repair_btn',
          chapterId: 'receive-returns',
          screenId: GuideScreenId.stock,
          routePath: '/stock',
          primaryTabIndex: 2,
          targetId: GuideTargetId.stockRepairAction,
          titleEn: 'Repair Damaged Button',
          titleGu: 'ડેમેજ રિપેર બટન',
          actionDescriptionEn:
              'Moves repaired pieces from the Damaged Stock bucket back into Good Stock with an audited reason and timestamp.',
          actionDescriptionGu:
              'રિપેર થયેલા પીસને ડેમેજ સ્ટોકમાંથી ઓડિટ નોંધ સાથે ફરી સારા સ્ટોકમાં લાવે છે.',
          nextActionHintEn:
              'Next Chapter: Open Labour & Payments to settle worker accounts.',
          nextActionHintGu:
              'આગળનું પ્રકરણ: હવે મજૂરી, એડવાન્સ અને કારીગર ખાતાવહી જોઈએ.',
          speechEn:
              'Damaged pieces stay in a separate bucket. Use Repair Damaged whenever defective pieces are fixed and ready for use again.',
          speechGu:
              'ડેમેજ પીસ અલગ સ્ટોકમાં રહે છે. જ્યારે તે રિપેર થઈ જાય ત્યારે ડેમેજ રિપેર બટનથી ફરી સારા સ્ટોકમાં લાવી શકાય છે.',
        ),
      ],
    ),

    // ── Chapter 8: Payments, Advances & Worker Ledger ──────────────────────
    GuideChapter(
      id: 'payments-ledger',
      order: 8,
      screenId: GuideScreenId.accounting,
      routePath: '/accounting',
      iconKey: 'accounting',
      titleEn: 'Payments, Advances & Worker Ledger',
      titleGu: 'ચુકવણી, એડવાન્સ અને કારીગર ખાતાવહી',
      summaryEn:
          'Pay workers via Cash/UPI/Bank, track Advance Credit separately from Outstanding Payable, and review running ledgers.',
      summaryGu:
          'રોકડ/UPI/બેંકથી પગાર ચૂકવો, એડવાન્સ જમા અને ચૂકવવાની બાકી અલગ જુઓ અને સંપૂર્ણ ખાતાવહી તપાસો.',
      nextStepLabelEn: 'Next: Reports, Export, App PIN Lock & Safe Backups',
      nextStepLabelGu: 'આગળ: રિપોર્ટ્સ, એક્સપોર્ટ, App PIN અને બેકઅપ સુરક્ષા',
      relatedHelpTopicIds: ['advances-and-payments', 'worker-ledger'],
      steps: [
        GuideStep(
          id: 'ch8_record_payment',
          chapterId: 'payments-ledger',
          screenId: GuideScreenId.accounting,
          routePath: '/accounting',
          targetId: GuideTargetId.accountingRecordPaymentAction,
          isInteractiveAction: true,
          titleEn: 'Record Payment / Advance Button',
          titleGu: 'ચુકવણી / એડવાન્સ નોંધો બટન',
          actionDescriptionEn:
              'Logs Regular Payment, Advance Payment, or Advance Refund with payment mode and reference number. Tap any worker row below to open their full ledger.',
          actionDescriptionGu:
              'નિયમિત પગાર, એડવાન્સ અથવા એડવાન્સ પરત નોંધે છે. નીચે કોઈપણ કારીગર પર ટેપ કરીને તેમની સંપૂર્ણ ખાતાવહી જુઓ.',
          nextActionHintEn:
              'Next Chapter: Inspect Business Reports, PDF/Excel Export, PIN Lock & Backups.',
          nextActionHintGu:
              'આગળનું પ્રકરણ: હવે રિપોર્ટ્સ, PDF/Excel એક્સપોર્ટ અને ડેટા સુરક્ષા જોઈએ.',
          speechEn:
              'In Accounting, tap Record Payment to pay wages or give an advance. Positive balance means payable to worker; negative means advance credit.',
          speechGu:
              'હિસાબ વિભાગમાં ચુકવણી નોંધો બટનથી પગાર કે એડવાન્સ લખી શકાય છે. ધન બેલેન્સ એટલે ચૂકવવાની બાકી અને ઋણ બેલેન્સ એટલે એડવાન્સ જમા.',
        ),
      ],
    ),

    // ── Chapter 9: Reports, Export, PIN Security & Backup ──────────────────
    GuideChapter(
      id: 'reports-history-safety',
      order: 9,
      screenId: GuideScreenId.reports,
      routePath: '/reports',
      iconKey: 'reports',
      titleEn: 'Reports, Export & Data Backup Safety',
      titleGu: 'રિપોર્ટ્સ, એક્સપોર્ટ અને બેકઅપ સુરક્ષા',
      summaryEn:
          'Filter 6 live business report categories, export PDF/Excel/CSV, protect access with App PIN, and take verified ZIP backups.',
      summaryGu:
          '૬ લાઇવ રિપોર્ટ વિભાગો ફિલ્ટર કરો, PDF/Excel એક્સપોર્ટ કરો, App PIN લોક રાખો અને નિયમિત ZIP બેકઅપ લો.',
      nextStepLabelEn: 'Training Complete! You can replay any chapter anytime.',
      nextStepLabelGu: 'તાલીમ પૂર્ણ! તમે ગમે ત્યારે કોઈપણ પ્રકરણ ફરી જોઈ શકો છો.',
      relatedHelpTopicIds: [
        'viewing-reports',
        'advanced-reports-and-export',
        'backup-and-restore',
        'app-pin-and-biometrics',
      ],
      steps: [
        GuideStep(
          id: 'ch9_reports_filter',
          chapterId: 'reports-history-safety',
          screenId: GuideScreenId.reports,
          routePath: '/reports',
          targetId: GuideTargetId.reportsFilterBar,
          titleEn: 'Date Presets & Smart Filters',
          titleGu: 'તારીખ અને સ્માર્ટ ફિલ્ટર',
          actionDescriptionEn:
              'Filter all reports by Today, This Week, This Month, or narrow by specific Worker, Process, Lot, or Colour.',
          actionDescriptionGu:
              'આજે, આ અઠવાડિયું, આ મહિનો અથવા ખાસ કારીગર, પ્રક્રિયા, લોટ કે રંગ મુજબ બધા રિપોર્ટ ફિલ્ટર કરો.',
          nextActionHintEn:
              'Next: See the Export button to save Gujarati-safe PDF or Excel.',
          nextActionHintGu:
              'આગળ: ગુજરાતી PDF કે Excel સેવ કરવા માટે એક્સપોર્ટ બટન જુઓ.',
          speechEn:
              'Use the Date and Filter bar to slice workshop reports by day, week, month, worker, or lot.',
          speechGu:
              'તારીખ અને ફિલ્ટર બાર વડે તમે આજનો, સાપ્તાહિક કે માસિક રિપોર્ટ કારીગર કે લોટ મુજબ જોઈ શકો છો.',
        ),
        GuideStep(
          id: 'ch9_reports_export',
          chapterId: 'reports-history-safety',
          screenId: GuideScreenId.reports,
          routePath: '/reports',
          targetId: GuideTargetId.reportsExportAction,
          titleEn: 'Export & Share (PDF / Excel / CSV)',
          titleGu: 'એક્સપોર્ટ અને શેર (PDF / Excel / CSV)',
          actionDescriptionEn:
              'Prints or shares clean English & Gujarati PDF reports, multi-sheet Excel workbooks (.xlsx), or CSV files.',
          actionDescriptionGu:
              'અંગ્રેજી અને ગુજરાતીમાં PDF પ્રિન્ટ/સેવ, Excel (.xlsx) વર્કબુક અથવા CSV ફાઇલ બનાવીને શેર કરે છે.',
          nextActionHintEn:
              'Final Tip: Remember to take weekly ZIP Backups in Settings -> Backup & Data Safety!',
          nextActionHintGu:
              'અંતિમ ટિપ: દર અઠવાડિયે સેટિંગ્સ -> બેકઅપ અને ડેટા સુરક્ષામાંથી ZIP બેકઅપ લેવાનું ભૂલશો નહીં!',
          speechEn:
              'Tap Export to share PDF or Excel reports. You have completed the end-to-end training! Remember to create regular ZIP backups in Settings.',
          speechGu:
              'એક્સપોર્ટ બટનથી PDF કે Excel રિપોર્ટ શેર કરી શકાય છે. તમારી સંપૂર્ણ તાલીમ પૂરી થઈ! સેટિંગ્સમાંથી નિયમિત ZIP બેકઅપ લેતા રહો.',
        ),
      ],
    ),
  ];

  /// Per-screen focused button-upper spotlight tours (triggered via the `?`
  /// Guide button or first-visit screen hint on any screen).
  static Map<String, List<GuideStep>> get screenTours => {
    GuideScreenId.home: chapters[0].steps,
    GuideScreenId.processes: chapters[2].steps,
    GuideScreenId.workers: chapters[3].steps,
    GuideScreenId.lots: chapters[4].steps,
    GuideScreenId.stock: <GuideStep>[
      ...chapters[5].steps,
      ...chapters[6].steps,
      const GuideStep(
        id: 'screen_stock_tabs',
        chapterId: 'receive-returns',
        screenId: GuideScreenId.stock,
        routePath: '/stock',
        primaryTabIndex: 2,
        targetId: GuideTargetId.stockTabs,
        titleEn: 'Stock Views (Pending, Live, History, Summary)',
        titleGu: 'સ્ટોક વિભાગો (બાકી, લાઇવ, ઇતિહાસ, સારાંશ)',
        actionDescriptionEn:
            'Switch between Pending Returns waiting with workers, Live Good/Damaged Stock, complete Movement History, and Worker/Process balances.',
        actionDescriptionGu:
            'કારીગર પાસે બાકી માલ, લાઇવ સારો/ડેમેજ સ્ટોક, સંપૂર્ણ હેરફેર ઇતિહાસ અને કારીગર/પ્રક્રિયા સારાંશ વચ્ચે સ્વિચ કરો.',
        nextActionHintEn:
            'Tip: Tap any Pending Return card to record returned pieces in seconds.',
        nextActionHintGu:
            'ટિપ: કોઈપણ બાકી પરત કાર્ડ પર ટેપ કરીને તરત પરત નોંધો.',
        speechEn:
            'Use these Stock tabs to check pending returns, live inventory, full history, and worker summaries.',
        speechGu:
            'આ સ્ટોક ટેબ્સથી બાકી પરત, લાઇવ સ્ટોક, ઇતિહાસ અને કારીગર સારાંશ જોઈ શકાય છે.',
      ),
    ],
    GuideScreenId.accounting: <GuideStep>[
      ...chapters[7].steps,
      const GuideStep(
        id: 'screen_accounting_tabs',
        chapterId: 'payments-ledger',
        screenId: GuideScreenId.accounting,
        routePath: '/accounting',
        targetId: GuideTargetId.accountingTabs,
        titleEn: 'Accounts, Earned Labour & Payment History',
        titleGu: 'ખાતાઓ, કમાયેલ મજૂરી અને ચુકવણી ઇતિહાસ',
        actionDescriptionEn:
            'Switch between each worker\'s net balance, detailed earned labour entries, and all payment/advance records.',
        actionDescriptionGu:
            'દરેક કારીગરનું ચોખ્ખું બેલેન્સ, કમાયેલ મજૂરીની વિગતો અને બધી ચુકવણી/એડવાન્સ નોંધો અલગ-અલગ જુઓ.',
        nextActionHintEn:
            'Tip: Tap any worker card to inspect their full running ledger or add an audited adjustment.',
        nextActionHintGu:
            'ટિપ: સંપૂર્ણ ખાતાવહી જોવા અથવા બોનસ/કપાત ઉમેરવા કોઈપણ કારીગર કાર્ડ પર ટેપ કરો.',
        speechEn:
            'Switch tabs here to view Worker Accounts, Earned Labour, and Payment History. Tap any worker to open their full ledger.',
        speechGu:
            'અહીંથી કારીગર ખાતા, કમાયેલ મજૂરી અને ચુકવણી ઇતિહાસ અલગ જોઈ શકાય છે. સંપૂર્ણ ખાતાવહી માટે કારીગર પર ટેપ કરો.',
      ),
    ],
    GuideScreenId.reports: <GuideStep>[
      ...chapters[8].steps,
      const GuideStep(
        id: 'screen_reports_categories',
        chapterId: 'reports-history-safety',
        screenId: GuideScreenId.reports,
        routePath: '/reports',
        targetId: GuideTargetId.reportsCategories,
        titleEn: '6 Business Report Categories',
        titleGu: '૬ વ્યવસાય રિપોર્ટ વિભાગો',
        actionDescriptionEn:
            'Swipe across Daily Workshop, Worker Performance, Process Performance, Inventory, Labour & Financial, and Business Insights.',
        actionDescriptionGu:
            'દૈનિક વર્કશોપ, કારીગર કામગીરી, પ્રક્રિયા કામગીરી, ઇન્વેન્ટરી, મજૂરી હિસાબ અને વ્યવસાયિક વિશ્લેષણ વચ્ચે સ્વિચ કરો.',
        nextActionHintEn:
            'Tip: Use Business Insights to spot slow processes and oldest pending work.',
        nextActionHintGu:
            'ટિપ: કઈ પ્રક્રિયામાં માલ અટક્યો છે તે જોવા "વ્યવસાયિક વિશ્લેષણ" ખોલો.',
        speechEn:
            'Choose between six report categories including Daily Workshop, Worker Performance, Inventory, Financial, and Business Insights.',
        speechGu:
            'અહીંથી દૈનિક વર્કશોપ, કારીગર કામગીરી, સ્ટોક, હિસાબ અને વ્યવસાયિક વિશ્લેષણ જેવા ૬ રિપોર્ટ જોઈ શકાય છે.',
      ),
    ],
    GuideScreenId.settings: <GuideStep>[
      const GuideStep(
        id: 'screen_settings_appearance',
        chapterId: 'business-setup',
        screenId: GuideScreenId.settings,
        routePath: '/settings',
        primaryTabIndex: 4,
        targetId: GuideTargetId.settingsAppearanceTile,
        titleEn: 'Language, Theme & Density',
        titleGu: 'ભાષા, થીમ અને દેખાવ',
        actionDescriptionEn:
            'Switch anytime between English and ગુજરાતી, Light or Dark theme, and comfortable or compact spacing.',
        actionDescriptionGu:
            'ગમે ત્યારે અંગ્રેજી અને ગુજરાતી ભાષા, લાઇટ કે ડાર્ક થીમ અને સ્ક્રીન સાઇઝ બદલો.',
        nextActionHintEn:
            'Next: Check Business Profile and Stock/Labour preferences below.',
        nextActionHintGu:
            'આગળ: નીચે બિઝનેસ પ્રોફાઇલ અને સ્ટોક/મજૂરી નિયમો જુઓ.',
        speechEn:
            'Appearance lets you switch between English and Gujarati, light and dark themes, and display density.',
        speechGu:
            'દેખાવ અને ભાષામાંથી તમે ગમે ત્યારે અંગ્રેજી કે ગુજરાતી અને લાઇટ કે ડાર્ક થીમ બદલી શકો છો.',
      ),
      ...chapters[1].steps,
      const GuideStep(
        id: 'screen_settings_security',
        chapterId: 'reports-history-safety',
        screenId: GuideScreenId.settings,
        routePath: '/settings',
        primaryTabIndex: 4,
        targetId: GuideTargetId.settingsSecurityTile,
        titleEn: 'App PIN & Biometric Lock',
        titleGu: 'App PIN અને ફિંગરપ્રિન્ટ લોક',
        actionDescriptionEn:
            'Protects workshop rates, stock, and worker ledgers with a 4- or 6-digit offline PIN, fingerprint unlock, and recovery key.',
        actionDescriptionGu:
            'કારખાનાના ભાવ, સ્ટોક અને હિસાબને ૪ કે ૬ અંકના ઓફલાઇન PIN અને ફિંગરપ્રિન્ટથી સુરક્ષિત રાખે છે.',
        nextActionHintEn:
            'Next: Protect your offline data with Backup & Restore.',
        nextActionHintGu:
            'આગળ: બેકઅપ અને ડેટા સુરક્ષા વિકલ્પ જુઓ.',
        speechEn:
            'Enable App PIN and Fingerprint Lock here to protect your workshop accounts on shared phones.',
        speechGu:
            'તમારા ફોન પર કારખાનાના હિસાબને સુરક્ષિત રાખવા અહીંથી App PIN અને ફિંગરપ્રિન્ટ લોક ચાલુ કરી શકાય છે.',
      ),
      const GuideStep(
        id: 'screen_settings_backup',
        chapterId: 'reports-history-safety',
        screenId: GuideScreenId.settings,
        routePath: '/settings',
        primaryTabIndex: 4,
        targetId: GuideTargetId.settingsBackupTile,
        titleEn: 'Backup & Data Safety (.zip)',
        titleGu: 'બેકઅપ અને ડેટા સુરક્ષા (.zip)',
        actionDescriptionEn:
            'Creates a full verified ZIP backup of your offline database and all lot photos so you can restore safely on any phone.',
        actionDescriptionGu:
            'તમારા ઓફલાઇન ડેટાબેઝ અને બધા લોટ ફોટાનો સંપૂર્ણ ZIP બેકઅપ બનાવે છે જેથી કોઈપણ ફોનમાં સુરક્ષિત રિસ્ટોર કરી શકાય.',
        nextActionHintEn:
            'Next: Open Help & User Guide anytime to replay voice training.',
        nextActionHintGu:
            'આગળ: અવાજ સાથેની સંપૂર્ણ તાલીમ ફરી જોવા "મદદ અને માર્ગદર્શન" ખોલો.',
        speechEn:
            'Use Backup and Data Safety once a week to save a full ZIP backup of your database and photos.',
        speechGu:
            'અઠવાડિયે એકવાર બેકઅપ અને ડેટા સુરક્ષામાંથી સંપૂર્ણ ZIP બેકઅપ બનાવીને સુરક્ષિત રાખો.',
      ),
      const GuideStep(
        id: 'screen_settings_help',
        chapterId: 'dashboard-overview',
        screenId: GuideScreenId.settings,
        routePath: '/settings',
        primaryTabIndex: 4,
        targetId: GuideTargetId.settingsHelpTile,
        titleEn: 'Interactive Training & User Guide Hub',
        titleGu: 'ઇન્ટરેક્ટિવ તાલીમ અને સંપૂર્ણ યુઝર ગાઇડ',
        actionDescriptionEn:
            'Replay the 9-chapter guided training, launch live button tours for any screen, or listen to all 19 workshop guides in English or Gujarati.',
        actionDescriptionGu:
            '૯ પ્રકરણની સંપૂર્ણ તાલીમ ફરી જુઓ, કોઈપણ સ્ક્રીનનું લાઇવ માર્ગદર્શન શરૂ કરો અથવા ૧૯ વર્કશોપ ગાઇડ સાંભળો.',
        nextActionHintEn:
            'Tip: You can also tap the (?) Guide icon in the top bar from any screen.',
        nextActionHintGu:
            'ટિપ: કોઈપણ સ્ક્રીન પર ઉપરનું (?) માર્ગદર્શન બટન દબાવીને તરત ગાઇડ ખોલી શકાય છે.',
        speechEn:
            'Help and User Guide holds the full nine-chapter interactive training and all nineteen voice-enabled guides.',
        speechGu:
            'મદદ અને માર્ગદર્શનમાં ૯ પ્રકરણની લાઇવ તાલીમ અને ૧૯ સંપૂર્ણ વર્કશોપ ગાઇડ અવાજ સાથે ઉપલબ્ધ છે.',
      ),
    ],
    GuideScreenId.lotDetail: const <GuideStep>[
      GuideStep(
        id: 'screen_lot_detail_design',
        chapterId: 'lots-designs-colours',
        screenId: GuideScreenId.lotDetail,
        routePath: '/lots',
        targetId: GuideTargetId.lotDetailAddDesign,
        titleEn: 'Add Design & Colours Inside Lot',
        titleGu: 'લોટમાં ડિઝાઇન અને રંગ ઉમેરો',
        actionDescriptionEn:
            'Add each Design code here, then add Colours with initial piece quantities and piece prices so stock becomes ready to issue.',
        actionDescriptionGu:
            'અહીં દરેક ડિઝાઇન કોડ ઉમેરો અને તેની અંદર રંગ, શરૂઆતનો જથ્થો તથા ભાવ નોંધો જેથી સ્ટોક આપવા તૈયાર બને.',
        nextActionHintEn:
            'Next: After adding Colours, use Stock Issue or Process Routing to start production.',
        nextActionHintGu:
            'આગળ: રંગ ઉમેર્યા પછી સ્ટોક આપો અથવા પ્રોસેસ રાઉટિંગ દ્વારા કામ શરૂ કરો.',
        speechEn:
            'Tap Add Design to organize styles inside this lot, then add each colour and starting piece quantity.',
        speechGu:
            'આ લોટમાં નવી ડિઝાઇન ઉમેરવા આ બટન દબાવો અને પછી દરેક રંગનો શરૂઆતનો જથ્થો ઉમેરો.',
      ),
      GuideStep(
        id: 'screen_lot_detail_routing',
        chapterId: 'lots-designs-colours',
        screenId: GuideScreenId.lotDetail,
        routePath: '/lots',
        targetId: GuideTargetId.lotDetailRouting,
        titleEn: 'Process Routing & Stage Progress',
        titleGu: 'પ્રોસેસ રાઉટિંગ અને પ્રગતિ',
        actionDescriptionEn:
            'Track piece movement across multiple custom production stages and transfer completed pieces to the next process.',
        actionDescriptionGu:
            'અલગ-અલગ પ્રક્રિયાઓ વચ્ચે પીસની પ્રગતિ ટ્રેક કરો અને તૈયાર પીસ આગળની પ્રક્રિયામાં મોકલો.',
        nextActionHintEn:
            'Tip: Every Lot also keeps a full Production History timeline.',
        nextActionHintGu:
            'ટિપ: દરેક લોટનો સંપૂર્ણ પ્રોડક્શન ઇતિહાસ પણ અહીંથી જોઈ શકાય છે.',
        speechEn:
            'Process Routing shows stage-by-stage progress across your custom workshop processes.',
        speechGu:
            'પ્રોસેસ રાઉટિંગથી દરેક પ્રક્રિયામાં લોટની પ્રગતિ અને તબક્કાવાર સ્થિતિ જોઈ શકાય છે.',
      ),
    ],
    GuideScreenId.workerDetail: const <GuideStep>[
      GuideStep(
        id: 'screen_worker_assignments',
        chapterId: 'workers-and-rates',
        screenId: GuideScreenId.workerDetail,
        routePath: '/workers',
        targetId: GuideTargetId.workerDetailAssignments,
        titleEn: 'Assign Processes to Worker',
        titleGu: 'કારીગરને પ્રક્રિયા સોંપો',
        actionDescriptionEn:
            'Select which production processes this karigar handles so they appear automatically during Stock Issue.',
        actionDescriptionGu:
            'આ કારીગર કઈ પ્રક્રિયાનું કામ કરે છે તે પસંદ કરો જેથી સ્ટોક આપતી વખતે તેમનું નામ આપમેળે દેખાય.',
        nextActionHintEn:
            'Next: Set their per-piece Rate for each assigned process.',
        nextActionHintGu:
            'આગળ: સોંપેલી દરેક પ્રક્રિયા માટે પીસ દીઠ ભાવ સેટ કરો.',
        speechEn:
            'Tap Manage Assignments to link this worker to the processes they work on.',
        speechGu:
            'આ કારીગરને તેમની પ્રક્રિયાઓ સાથે જોડવા પ્રક્રિયા સોંપણી પર ટેપ કરો.',
      ),
      GuideStep(
        id: 'screen_worker_rates',
        chapterId: 'workers-and-rates',
        screenId: GuideScreenId.workerDetail,
        routePath: '/workers',
        targetId: GuideTargetId.workerDetailRates,
        titleEn: 'Effective-Dated Piece Rates',
        titleGu: 'તારીખ મુજબ પીસ દીઠ ભાવ',
        actionDescriptionEn:
            'Set or revise this worker\'s per-piece rate with an effective IST date. Old transactions keep their locked historical rate.',
        actionDescriptionGu:
            'અમલી તારીખ સાથે પીસ દીઠ ભાવ સેટ કે અપડેટ કરો. જૂના વ્યવહારોનો લોક કરેલો ભાવ ક્યારેય બદલાતો નથી.',
        nextActionHintEn:
            'Next: View Worker Ledger to check Earned Labour, Advances, and Net Payable.',
        nextActionHintGu:
            'આગળ: કમાયેલ મજૂરી, એડવાન્સ અને બાકી હિસાબ જોવા ખાતાવહી ખોલો.',
        speechEn:
            'Use Rates to set effective-dated per-piece rates so future revisions never change past accounts.',
        speechGu:
            'ભાવ વિભાગમાંથી અમલી તારીખ સાથે પીસ દીઠ ભાવ સેટ કરો જેથી જૂનો હિસાબ હંમેશા ચોક્કસ રહે.',
      ),
      GuideStep(
        id: 'screen_worker_ledger',
        chapterId: 'payments-ledger',
        screenId: GuideScreenId.workerDetail,
        routePath: '/workers',
        targetId: GuideTargetId.workerDetailLedger,
        titleEn: 'Worker Ledger & Account Statement',
        titleGu: 'કારીગર ખાતાવહી અને હિસાબ',
        actionDescriptionEn:
            'Opens the complete running balance of earned labour, advances, regular payouts, and audited adjustments.',
        actionDescriptionGu:
            'કમાયેલ મજૂરી, એડવાન્સ, નિયમિત ચુકવણી અને સમાયોજન સાથેની સંપૂર્ણ ચાલુ ખાતાવહી ખોલે છે.',
        nextActionHintEn:
            'Tip: You can share a WhatsApp / print slip directly from the ledger.',
        nextActionHintGu:
            'ટિપ: ખાતાવહીમાંથી સીધી હિસાબ સ્લિપ શેર કે પ્રિન્ટ કરી શકાય છે.',
        speechEn:
            'Open Worker Ledger anytime for weekly or monthly wage settlement.',
        speechGu:
            'સાપ્તાહિક કે માસિક પગાર હિસાબ માટે અહીંથી કારીગરની ખાતાવહી ખોલો.',
      ),
    ],
  };

  /// Flattened ordered list of every step across all 9 end-to-end chapters.
  static List<GuideStep> get allJourneySteps => <GuideStep>[
    for (final chapter in chapters) ...chapter.steps,
  ];

  static GuideChapter? chapterById(String id) {
    for (final chapter in chapters) {
      if (chapter.id == id) return chapter;
    }
    return null;
  }

  static int chapterIndexById(String id) {
    for (var i = 0; i < chapters.length; i++) {
      if (chapters[i].id == id) return i;
    }
    return 0;
  }

  /// Resolves the best per-screen tour steps for [screenId] (falls back to
  /// Dashboard overview if unknown).
  static List<GuideStep> stepsForScreen(String screenId) {
    return screenTours[screenId] ?? screenTours[GuideScreenId.home]!;
  }

  /// Maps every HelpTopic in `StitchFlowHelpCatalog` to its live screen,
  /// interactive chapter, and next recommended topic in the end-to-end flow.
  static const Map<String, HelpTopicActionLink> helpTopicLinks =
      <String, HelpTopicActionLink>{
        'getting-started': HelpTopicActionLink(
          topicId: 'getting-started',
          chapterId: 'dashboard-overview',
          liveRoutePath: '/',
          liveScreenId: GuideScreenId.home,
          primaryTabIndex: 0,
          nextTopicId: 'creating-processes',
        ),
        'creating-processes': HelpTopicActionLink(
          topicId: 'creating-processes',
          chapterId: 'processes-setup',
          liveRoutePath: '/processes',
          liveScreenId: GuideScreenId.processes,
          nextTopicId: 'adding-workers',
        ),
        'adding-workers': HelpTopicActionLink(
          topicId: 'adding-workers',
          chapterId: 'workers-and-rates',
          liveRoutePath: '/workers',
          liveScreenId: GuideScreenId.workers,
          primaryTabIndex: 3,
          nextTopicId: 'assigning-workers',
        ),
        'assigning-workers': HelpTopicActionLink(
          topicId: 'assigning-workers',
          chapterId: 'workers-and-rates',
          liveRoutePath: '/workers',
          liveScreenId: GuideScreenId.workers,
          primaryTabIndex: 3,
          nextTopicId: 'setting-worker-rates',
        ),
        'setting-worker-rates': HelpTopicActionLink(
          topicId: 'setting-worker-rates',
          chapterId: 'workers-and-rates',
          liveRoutePath: '/workers',
          liveScreenId: GuideScreenId.workers,
          primaryTabIndex: 3,
          nextTopicId: 'creating-a-lot',
        ),
        'creating-a-lot': HelpTopicActionLink(
          topicId: 'creating-a-lot',
          chapterId: 'lots-designs-colours',
          liveRoutePath: '/lots',
          liveScreenId: GuideScreenId.lots,
          primaryTabIndex: 1,
          nextTopicId: 'designs-and-colours',
        ),
        'designs-and-colours': HelpTopicActionLink(
          topicId: 'designs-and-colours',
          chapterId: 'lots-designs-colours',
          liveRoutePath: '/lots',
          liveScreenId: GuideScreenId.lots,
          primaryTabIndex: 1,
          nextTopicId: 'issuing-stock',
        ),
        'issuing-stock': HelpTopicActionLink(
          topicId: 'issuing-stock',
          chapterId: 'issue-stock',
          liveRoutePath: '/stock',
          liveScreenId: GuideScreenId.stock,
          primaryTabIndex: 2,
          nextTopicId: 'receiving-returns',
        ),
        'receiving-returns': HelpTopicActionLink(
          topicId: 'receiving-returns',
          chapterId: 'receive-returns',
          liveRoutePath: '/stock',
          liveScreenId: GuideScreenId.stock,
          primaryTabIndex: 2,
          nextTopicId: 'damaged-lost-shortage',
        ),
        'damaged-lost-shortage': HelpTopicActionLink(
          topicId: 'damaged-lost-shortage',
          chapterId: 'receive-returns',
          liveRoutePath: '/stock',
          liveScreenId: GuideScreenId.stock,
          primaryTabIndex: 2,
          nextTopicId: 'worker-labour',
        ),
        'worker-labour': HelpTopicActionLink(
          topicId: 'worker-labour',
          chapterId: 'business-setup',
          liveRoutePath: '/settings',
          liveScreenId: GuideScreenId.settings,
          primaryTabIndex: 4,
          nextTopicId: 'advances-and-payments',
        ),
        'advances-and-payments': HelpTopicActionLink(
          topicId: 'advances-and-payments',
          chapterId: 'payments-ledger',
          liveRoutePath: '/accounting',
          liveScreenId: GuideScreenId.accounting,
          nextTopicId: 'worker-ledger',
        ),
        'worker-ledger': HelpTopicActionLink(
          topicId: 'worker-ledger',
          chapterId: 'payments-ledger',
          liveRoutePath: '/accounting',
          liveScreenId: GuideScreenId.accounting,
          nextTopicId: 'viewing-reports',
        ),
        'viewing-reports': HelpTopicActionLink(
          topicId: 'viewing-reports',
          chapterId: 'reports-history-safety',
          liveRoutePath: '/reports',
          liveScreenId: GuideScreenId.reports,
          nextTopicId: 'advanced-reports-and-export',
        ),
        'advanced-reports-and-export': HelpTopicActionLink(
          topicId: 'advanced-reports-and-export',
          chapterId: 'reports-history-safety',
          liveRoutePath: '/reports',
          liveScreenId: GuideScreenId.reports,
          nextTopicId: 'backup-and-restore',
        ),
        'backup-and-restore': HelpTopicActionLink(
          topicId: 'backup-and-restore',
          chapterId: 'reports-history-safety',
          liveRoutePath: '/settings',
          liveScreenId: GuideScreenId.settings,
          primaryTabIndex: 4,
          nextTopicId: 'app-pin-and-biometrics',
        ),
        'app-pin-and-biometrics': HelpTopicActionLink(
          topicId: 'app-pin-and-biometrics',
          chapterId: 'reports-history-safety',
          liveRoutePath: '/settings',
          liveScreenId: GuideScreenId.settings,
          primaryTabIndex: 4,
          nextTopicId: 'pin-recovery-and-lock-safety',
        ),
        'pin-recovery-and-lock-safety': HelpTopicActionLink(
          topicId: 'pin-recovery-and-lock-safety',
          chapterId: 'reports-history-safety',
          liveRoutePath: '/settings',
          liveScreenId: GuideScreenId.settings,
          primaryTabIndex: 4,
          nextTopicId: 'local-reminders-notifications',
        ),
        'local-reminders-notifications': HelpTopicActionLink(
          topicId: 'local-reminders-notifications',
          chapterId: 'business-setup',
          liveRoutePath: '/settings',
          liveScreenId: GuideScreenId.settings,
          primaryTabIndex: 4,
          nextTopicId: null,
        ),
      };
}
