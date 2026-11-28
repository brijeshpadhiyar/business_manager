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
      summaryEn: 'Learn the home screen layout, 1-tap workshop quick actions, search, and where to replay guidance anytime.',
      summaryGu: 'હોમ સ્ક્રીન, ૧-ટેપ વર્કશોપ ઝડપી બટનો, શોધ અને ગમે ત્યારે માર્ગદર્શન કેવી રીતે ફરી શરૂ કરવું તે સમજો.',
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
          actionDescriptionEn: 'Tap this button on any screen to highlight what every button does, turn Voice ON/OFF, or open the full User Guide.',
          actionDescriptionGu: 'કોઈપણ સ્ક્રીન પર આ બટન દબાવો અને જાણો કે દરેક બટન શું કામ કરે છે, અવાજ ચાલુ/બંધ કરો અથવા સંપૂર્ણ યુઝર ગાઇડ ખોલો.',
          nextActionHintEn:
              'Next: Tap Next to see how Quick Actions speed up daily work.',
          nextActionHintGu:
              'આગળ: રોજિંદા કામ ઝડપી બનાવતા બટનો જોવા માટે "આગળ" દબાવો.',
          speechEn: 'Welcome to Business Manager. This Guide button is always at the top. Tap it on any screen to hear what every button does.',
          speechGu: 'બિઝનેસ મેનેજરમાં તમારું સ્વાગત છે. આ માર્ગદર્શન બટન હંમેશા ઉપર રહે છે. કોઈપણ સ્ક્રીન પર દરેક બટનનું કામ જાણવા આ બટન દબાવો.',
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
          actionDescriptionEn: 'Instantly find any Lot number, Worker name, Work Stage, or jump directly to Issue Stock, Receive Return, or Payment.',
          actionDescriptionGu: 'કોઈપણ લોટ નંબર, કારીગરનું નામ, તબક્કો તરત શોધો અથવા સીધા સ્ટોક આપો, પરત લો કે ચુકવણી ખોલો.',
          nextActionHintEn:
              'Next: Explore the 6 everyday Quick Action tiles right below.',
          nextActionHintGu: 'આગળ: નીચે આપેલા ૬ રોજિંદા ઝડપી બટનો સમજો.',
          speechEn: 'Use Global Search to find any lot, worker, or work stage in one second.',
          speechGu:
              'ઝડપી શોધ વડે તમે કોઈપણ લોટ, કારીગર કે તબક્કો તરત જ શોધી શકો છો.',
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
          actionDescriptionEn: 'Gives available in-house pieces to a worker for any work stage and automatically locks the piece rate.',
          actionDescriptionGu: 'ગોડાઉનમાં ઉપલબ્ધ સારા પીસ કોઈપણ તબક્કા માટે કારીગરને આપે છે અને પીસ દીઠ ભાવ આપમેળે લોક કરે છે.',
          nextActionHintEn: 'Next: Look at Receive Return right beside it.',
          nextActionHintGu: 'આગળ: તેની બાજુમાં આવેલ "માલ પરત લો" બટન જુઓ.',
          speechEn: 'Issue Stock lets you give good pieces to a worker and automatically locks their rate for that date.',
          speechGu: 'સ્ટોક આપો બટનથી તમે કારીગરને કામ માટે સારા પીસ આપી શકો છો અને તે તારીખનો ભાવ આપમેળે લોક થઈ જાય છે.',
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
          actionDescriptionEn: 'Records Good, Damaged, Lost, or Shortage pieces brought back by a worker and updates earned labour automatically.',
          actionDescriptionGu: 'કારીગર પાસેથી પરત આવેલ સારા, ડેમેજ, ખોવાયેલ કે ઘટ પીસ નોંધે છે અને કમાયેલ મજૂરી આપમેળે ઉમેરે છે.',
          nextActionHintEn:
              'Next: Check how worker payments and new lots start from here.',
          nextActionHintGu: 'આગળ: કારીગર ચુકવણી અને નવા લોટના ઝડપી બટનો જુઓ.',
          speechEn: 'Receive Work records returned good, damaged, or lost pieces and calculates worker labour automatically.',
          speechGu: 'માલ પરત લો બટનથી કારીગર પાસેથી આવેલ સારા, ડેમેજ કે ખોવાયેલ પીસ નોંધાય છે અને મજૂરી આપમેળે ગણાય છે.',
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
          actionDescriptionEn: 'Logs cash, UPI, or bank wage payouts and keeps Advance Credit separate from Earned Labour.',
          actionDescriptionGu: 'રોકડ, UPI કે બેંક દ્વારા પગાર અથવા એડવાન્સ નોંધે છે અને એડવાન્સ જમા રકમને મજૂરીથી અલગ રાખે છે.',
          nextActionHintEn: 'Next: See the bottom tabs to move across Lots, Stock, Workers, and Settings.',
          nextActionHintGu: 'આગળ: લોટ્સ, સ્ટોક, કારીગરો અને સેટિંગ્સ વચ્ચે જવા માટે મુખ્ય મેનુ જુઓ.',
          speechEn: 'Record Payment saves worker wages or advances via cash, UPI, or bank transfer.',
          speechGu: 'ચુકવણી નોંધો બટનથી કારીગરને આપેલ પગાર કે એડવાન્સ રોકડ, UPI કે બેંક વિગત સાથે સાચવી શકાય છે.',
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
          actionDescriptionEn: 'Shows today\'s issued pieces, returned good pieces, earned labour, and payments. Tap any tile to drill into full details.',
          actionDescriptionGu: 'આજે આપેલા પીસ, પરત આવેલા પીસ, મજૂરી અને ચુકવણી લાઇવ બતાવે છે. કોઈપણ કાર્ડ પર ટેપ કરીને સંપૂર્ણ વિગત જુઓ.',
          nextActionHintEn: 'Next Chapter: We will open Settings to configure your Business Profile.',
          nextActionHintGu: 'આગળનું પ્રકરણ: હવે આપણે સેટિંગ્સમાં જઈને તમારા કારખાનાની પ્રોફાઇલ સમજીશું.',
          speechEn: 'These live tiles show today\'s workshop output and money. Tap any card anytime to inspect details. Let us move to Workshop Setup next.',
          speechGu: 'આ લાઇવ કાર્ડ આજનો સ્ટોક અને હિસાબ બતાવે છે. કોઈપણ કાર્ડ પર ટેપ કરીને વિગતો જોઈ શકાય છે. હવે આગળ કારખાનાનું સેટઅપ જોઈએ.',
        ),
      ],
    ),

    // ── Chapter 2: Workshop Profile & Billing Rules ────────────────────────
    GuideChapter(
      id: 'business-setup',
      order: 2,
      screenId: GuideScreenId.settings,
      routePath: '/settings',
      primaryTabIndex: 5,
      iconKey: 'business',
      titleEn: 'Workshop Profile & Billing Mode',
      titleGu: 'કારખાનાની પ્રોફાઇલ અને મજૂરી નિયમ',
      summaryEn: 'Configure your workshop name in English & Gujarati, theme/language, and whether labour is paid on Received or Given quantity.',
      summaryGu: 'તમારા કારખાનાનું નામ (અંગ્રેજી અને ગુજરાતી), ભાષા/થીમ અને મજૂરી ગણતરીનો મુખ્ય નિયમ સેટ કરો.',
      nextStepLabelEn: 'Next: Create your custom Work Stages',
      nextStepLabelGu: 'આગળ: તમારા કામના તબક્કા બનાવો',
      relatedHelpTopicIds: ['getting-started', 'worker-labour'],
      steps: [
        GuideStep(
          id: 'ch2_business_profile',
          chapterId: 'business-setup',
          screenId: GuideScreenId.settings,
          routePath: '/settings',
          primaryTabIndex: 5,
          targetId: GuideTargetId.settingsBusinessProfileTile,
          isInteractiveAction: true,
          titleEn: 'Business Profile',
          titleGu: 'બિઝનેસ પ્રોફાઇલ',
          actionDescriptionEn: 'Set your workshop name (English & Gujarati), owner name, phone, and address that appear on printed slips and PDF reports.',
          actionDescriptionGu: 'તમારા કારખાનાનું નામ (અંગ્રેજી અને ગુજરાતી), માલિકનું નામ, ફોન અને સરનામું સેટ કરો જે સ્લિપ અને PDF રિપોર્ટમાં છપાય છે.',
          nextActionHintEn: 'Do this first: Tap Business Profile to enter your shop name, or tap Next to continue the tour.',
          nextActionHintGu: 'પહેલા આ કરો: કારખાનાનું નામ ભરવા "બિઝનેસ પ્રોફાઇલ" ખોલો, અથવા ગાઇડ આગળ વધારવા "આગળ" દબાવો.',
          speechEn: 'Step one of workshop setup is Business Profile. Enter your workshop name here so it appears on every slip and report.',
          speechGu: 'સેટઅપનું પહેલું પગલું બિઝનેસ પ્રોફાઇલ છે. અહીં તમારા કારખાનાનું નામ લખો જેથી દરેક સ્લિપ અને રિપોર્ટમાં દેખાય.',
        ),
        GuideStep(
          id: 'ch2_stock_labour',
          chapterId: 'business-setup',
          screenId: GuideScreenId.settings,
          routePath: '/settings',
          primaryTabIndex: 5,
          targetId: GuideTargetId.settingsStockLabourTile,
          titleEn: 'Stock & Labour Rules',
          titleGu: 'સ્ટોક અને મજૂરી નિયમો',
          actionDescriptionEn: 'Choose default labour billing: Pay on Received Good Pieces (recommended) or Pay on Given Pieces, plus damaged-piece labour policy.',
          actionDescriptionGu: 'મજૂરીનો ડિફોલ્ટ નિયમ પસંદ કરો: મળેલા સારા પીસ પર મજૂરી (ભલામણ કરેલ) અથવા આપેલા પીસ પર મજૂરી.',
          nextActionHintEn: 'Next Chapter: Create your Work Stages (like Cutting, Stitching, Press).',
          nextActionHintGu: 'આગળનું પ્રકરણ: હવે તમારા કામના તબક્કા (કટિંગ, સ્ટિચિંગ, પ્રેસ) બનાવીએ.',
          speechEn: 'Stock and Labour Settings control whether workers earn labour when good pieces return or when stock is given. Next, let us open Work Stages.',
          speechGu: 'સ્ટોક અને મજૂરી સેટિંગ્સમાં નક્કી થાય છે કે મજૂરી સારો માલ પરત આવે ત્યારે ગણવી કે આપતી વખતે. હવે આગળ તબક્કા જોઈએ.',
        ),
      ],
    ),

    // ── Chapter 3: Work Stages ────────────────────────────────────
    GuideChapter(
      id: 'processes-setup',
      order: 3,
      screenId: GuideScreenId.processes,
      routePath: '/processes',
      primaryTabIndex: 4,
      iconKey: 'process',
      titleEn: 'Creating Work Stages',
      titleGu: 'કામના તબક્કા બનાવવા',
      summaryEn: 'Define any custom garment stages (Cutting, Stitching, Embroidery, Press, Packing) with zero fixed order.',
      summaryGu: 'કોઈપણ નક્કી ક્રમ વગર તમારા કારખાનાના કામના તબક્કા (કટિંગ, સ્ટિચિંગ, એમ્બ્રોઇડરી, પ્રેસ) બનાવો.',
      nextStepLabelEn: 'Next: Add Workers and set their Per-Piece Rates',
      nextStepLabelGu: 'આગળ: કારીગરો ઉમેરો અને તેમના પીસ દીઠ ભાવ સેટ કરો',
      relatedHelpTopicIds: ['creating-processes'],
      steps: [
        GuideStep(
          id: 'ch3_new_process',
          chapterId: 'processes-setup',
          screenId: GuideScreenId.processes,
          routePath: '/processes',
          primaryTabIndex: 4,
          targetId: GuideTargetId.processNewAction,
          isInteractiveAction: true,
          titleEn: 'New Work Stage Button',
          titleGu: 'નવો તબક્કો બટન',
          actionDescriptionEn: 'Creates a custom workshop stage (e.g., Cutting, Stitching, Overlock, Press). You can also set a default rate and stage-specific labour rule.',
          actionDescriptionGu: 'તમારા કારખાનાનો નવો કામનો તબક્કો બનાવે છે (દા.ત. કટિંગ, સ્ટિચિંગ, પ્રેસ). તમે ડિફોલ્ટ ભાવ અને અલગ મજૂરી નિયમ પણ રાખી શકો છો.',
          nextActionHintEn: 'Action: Tap New Work Stage to add your stages, then tap Next Chapter to add Workers.',
          nextActionHintGu: 'કાર્ય: નવો તબક્કો ઉમેરવા આ બટન દબાવો, પછી કારીગરો ઉમેરવા "આગળ" દબાવો.',
          speechEn: 'Here you create your work stages such as Cutting, Stitching, or Press. Open the Stages tab and tap New Work Stage to add them anytime. Next, we will add your workers.',
          speechGu: 'અહીં તમે કટિંગ, સ્ટિચિંગ કે પ્રેસ જેવા તમારા કામના તબક્કા બનાવી શકો છો. નવો તબક્કો ઉમેરવા આ બટન દબાવો. હવે આગળ કારીગરો જોઈએ.',
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
      summaryEn: 'Add each karigar, link them to the work stages they handle, and record effective-dated per-piece rates.',
      summaryGu: 'દરેક કારીગરને ઉમેરો, તેમને તબક્કો સોંપો અને તારીખ મુજબ પીસ દીઠ ભાવ સેટ કરો.',
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
          actionDescriptionEn: 'Adds a tailor, cutter, presser, or job-worker with phone and notes. After saving, open the worker to assign Work Stages and set per-piece Rates.',
          actionDescriptionGu: 'નવા કારીગરનું નામ, ફોન અને નોંધ ઉમેરે છે. સાચવ્યા પછી કારીગર ખોલીને તબક્કા સોંપણી અને પીસ દીઠ ભાવ સેટ કરો.',
          nextActionHintEn: 'Action: Tap New Worker to add a karigar, then open their profile to Assign Work Stage & Add Rate. Tap Next for Lots.',
          nextActionHintGu: 'કાર્ય: કારીગર ઉમેરવા આ બટન દબાવો, પછી તેમની પ્રોફાઇલમાં તબક્કો અને ભાવ સેટ કરો. હવે લોટ્સ જોવા "આગળ" દબાવો.',
          speechEn: 'Tap New Worker to add a karigar. Once saved, open any worker to assign their work stages and set historical per-piece rates. Next, let us create a Lot.',
          speechGu: 'નવો કારીગર ઉમેરવા આ બટન દબાવો. સાચવ્યા પછી કારીગરની પ્રોફાઇલ ખોલી તબક્કો સોંપો અને પીસ દીઠ ભાવ સેટ કરો. હવે આગળ લોટ બનાવતા શીખીએ.',
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
      summaryEn: 'Create each fabric batch as a Lot, add Designs inside it, and record Colours with initial good pieces and piece prices.',
      summaryGu: 'દરેક નવા કાપડ બેચનો લોટ બનાવો, તેની અંદર ડિઝાઇન અને રંગનો શરૂઆતનો જથ્થો તથા ભાવ નોંધો.',
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
          actionDescriptionEn: 'Creates a new garment batch with a unique Lot Number, IST date, and optional fabric photos. Inside the Lot, add Designs & Colours to put pieces into Available Good Stock.',
          actionDescriptionGu: 'અલગ લોટ નંબર, તારીખ અને ફોટા સાથે નવો લોટ બનાવે છે. લોટની અંદર ડિઝાઇન અને રંગ ઉમેરતા જ પીસ ઉપલબ્ધ સારા સ્ટોકમાં આવી જાય છે.',
          nextActionHintEn: 'Action: Tap New Lot -> Save -> Add Design -> Add Colour (Qty). Tap Next to learn Stock Issue.',
          nextActionHintGu: 'કાર્ય: નવો લોટ બનાવો -> સાચવો -> ડિઝાઇન ઉમેરો -> રંગ અને જથ્થો ઉમેરો. સ્ટોક આપતા શીખવા "આગળ" દબાવો.',
          speechEn: 'Tap New Lot whenever a new batch arrives. After saving, open the lot to add Designs and Colours with initial quantities so they become ready for issue.',
          speechGu: 'જ્યારે નવો માલ આવે ત્યારે નવો લોટ બટન દબાવો. સાચવ્યા પછી લોટમાં ડિઝાઇન અને રંગનો જથ્થો ઉમેરો જેથી તે સ્ટોક આપવા માટે તૈયાર થઈ જાય.',
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
      summaryEn: 'Issue available in-house good stock to an assigned worker in 4 guided steps with automatic rate locking.',
      summaryGu: 'ઉપલબ્ધ સારા સ્ટોકમાંથી સોંપેલા કારીગરને આપમેળે ભાવ લોક સાથે માલ આપો.',
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
          actionDescriptionEn: 'Opens the 4-step Stock Issue flow: Pick Lot/Colour -> Pick Work Stage & Eligible Worker -> Enter Quantity -> Confirm. Effective piece rate and billing rule lock automatically.',
          actionDescriptionGu: '૪ સ્ટેપમાં સ્ટોક આપવાનું ખોલે છે: લોટ/રંગ પસંદ કરો -> તબક્કો અને કારીગર પસંદ કરો -> પીસ લખો -> ખાતરી કરો. ભાવ અને નિયમ આપમેળે લોક થાય છે.',
          nextActionHintEn: 'Action: Tap Issue Stock whenever pieces leave your table. Tap Next to see Receive Return.',
          nextActionHintGu: 'કાર્ય: કારીગરને માલ આપવા આ બટન વાપરો. હવે માલ પરત લેતા શીખવા "આગળ" દબાવો.',
          speechEn: 'Tap Issue Stock to hand pieces to a worker. Pick the colour, work stage, worker, and quantity. Business Manager locks the exact piece rate automatically.',
          speechGu: 'કારીગરને પીસ આપવા સ્ટોક આપો બટન દબાવો. રંગ, તબક્કો, કારીગર અને પીસ પસંદ કરો. તે તારીખનો ભાવ આપમેળે લોક થઈ જશે.',
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
      summaryEn: 'Record full or partial returns, separate Damaged/Lost/Shortage safely, and repair salvaged pieces back to Good Stock.',
      summaryGu: 'પૂરો કે આંશિક માલ પરત લો, ડેમેજ/ખોવાયેલ/ઘટ અલગ નોંધો અને રિપેર થયેલ ડેમેજ પીસ ફરી સારા સ્ટોકમાં લાવો.',
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
          actionDescriptionEn: 'Pick any open pending issue and enter Good Returned (or tap All Good), plus any Damaged, Lost, or Shortage pieces with mandatory reason.',
          actionDescriptionGu: 'બાકી ઇશ્યૂ પસંદ કરો અને પરત આવેલા સારા પીસ (અથવા "બધો સારો") તથા ડેમેજ, ખોવાયેલ કે ઘટ પીસ કારણ સાથે નોંધો.',
          nextActionHintEn:
              'Next: See the Repair Damaged button and Stock Tabs right below.',
          nextActionHintGu: 'આગળ: ડેમેજ રિપેર બટન અને સ્ટોક વિભાગો જુઓ.',
          speechEn: 'When a worker brings pieces back, tap Receive Return. Only Good pieces return to available stock and earn labour by default.',
          speechGu: 'કારીગર માલ પરત લાવે ત્યારે માલ પરત લો બટન દબાવો. માત્ર સારા પીસ પાછા ગોડાઉનમાં આવે છે અને તેની મજૂરી જમા થાય છે.',
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
          actionDescriptionEn: 'Moves repaired pieces from the Damaged Stock bucket back into Good Stock with an audited reason and timestamp.',
          actionDescriptionGu: 'રિપેર થયેલા પીસને ડેમેજ સ્ટોકમાંથી ઓડિટ નોંધ સાથે ફરી સારા સ્ટોકમાં લાવે છે.',
          nextActionHintEn:
              'Next Chapter: Open Labour & Payments to settle worker accounts.',
          nextActionHintGu:
              'આગળનું પ્રકરણ: હવે મજૂરી, એડવાન્સ અને કારીગર ખાતાવહી જોઈએ.',
          speechEn: 'Damaged pieces stay in a separate bucket. Use Repair Damaged whenever defective pieces are fixed and ready for use again.',
          speechGu: 'ડેમેજ પીસ અલગ સ્ટોકમાં રહે છે. જ્યારે તે રિપેર થઈ જાય ત્યારે ડેમેજ રિપેર બટનથી ફરી સારા સ્ટોકમાં લાવી શકાય છે.',
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
      summaryEn: 'Pay workers via Cash/UPI/Bank, track Advance Credit separately from Outstanding Payable, and review running ledgers.',
      summaryGu: 'રોકડ/UPI/બેંકથી પગાર ચૂકવો, એડવાન્સ જમા અને ચૂકવવાની બાકી અલગ જુઓ અને સંપૂર્ણ ખાતાવહી તપાસો.',
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
          actionDescriptionEn: 'Logs Regular Payment, Advance Payment, or Advance Refund with payment mode and reference number. Tap any worker row below to open their full ledger.',
          actionDescriptionGu: 'નિયમિત પગાર, એડવાન્સ અથવા એડવાન્સ પરત નોંધે છે. નીચે કોઈપણ કારીગર પર ટેપ કરીને તેમની સંપૂર્ણ ખાતાવહી જુઓ.',
          nextActionHintEn: 'Next Chapter: Inspect Business Reports, PDF/Excel Export, PIN Lock & Backups.',
          nextActionHintGu: 'આગળનું પ્રકરણ: હવે રિપોર્ટ્સ, PDF/Excel એક્સપોર્ટ અને ડેટા સુરક્ષા જોઈએ.',
          speechEn: 'In Accounting, tap Record Payment to pay wages or give an advance. Positive balance means payable to worker; negative means advance credit.',
          speechGu: 'હિસાબ વિભાગમાં ચુકવણી નોંધો બટનથી પગાર કે એડવાન્સ લખી શકાય છે. ધન બેલેન્સ એટલે ચૂકવવાની બાકી અને ઋણ બેલેન્સ એટલે એડવાન્સ જમા.',
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
      summaryEn: 'Filter 6 live business report categories, export PDF/Excel/CSV, protect access with App PIN, and take verified ZIP backups.',
      summaryGu: '૬ લાઇવ રિપોર્ટ વિભાગો ફિલ્ટર કરો, PDF/Excel એક્સપોર્ટ કરો, App PIN લોક રાખો અને નિયમિત ZIP બેકઅપ લો.',
      nextStepLabelEn: 'Training Complete! You can replay any chapter anytime.',
      nextStepLabelGu:
          'તાલીમ પૂર્ણ! તમે ગમે ત્યારે કોઈપણ પ્રકરણ ફરી જોઈ શકો છો.',
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
          actionDescriptionEn: 'Filter all reports by Today, This Week, This Month, or narrow by specific Worker, Work Stage, Lot, or Colour.',
          actionDescriptionGu: 'આજે, આ અઠવાડિયું, આ મહિનો અથવા ખાસ કારીગર, તબક્કો, લોટ કે રંગ મુજબ બધા રિપોર્ટ ફિલ્ટર કરો.',
          nextActionHintEn:
              'Next: See the Export button to save Gujarati-safe PDF or Excel.',
          nextActionHintGu:
              'આગળ: ગુજરાતી PDF કે Excel સેવ કરવા માટે એક્સપોર્ટ બટન જુઓ.',
          speechEn: 'Use the Date and Filter bar to slice workshop reports by day, week, month, worker, or lot.',
          speechGu: 'તારીખ અને ફિલ્ટર બાર વડે તમે આજનો, સાપ્તાહિક કે માસિક રિપોર્ટ કારીગર કે લોટ મુજબ જોઈ શકો છો.',
        ),
        GuideStep(
          id: 'ch9_reports_export',
          chapterId: 'reports-history-safety',
          screenId: GuideScreenId.reports,
          routePath: '/reports',
          targetId: GuideTargetId.reportsExportAction,
          titleEn: 'Export & Share (PDF / Excel / CSV)',
          titleGu: 'એક્સપોર્ટ અને શેર (PDF / Excel / CSV)',
          actionDescriptionEn: 'Prints or shares clean English & Gujarati PDF reports, multi-sheet Excel workbooks (.xlsx), or CSV files.',
          actionDescriptionGu: 'અંગ્રેજી અને ગુજરાતીમાં PDF પ્રિન્ટ/સેવ, Excel (.xlsx) વર્કબુક અથવા CSV ફાઇલ બનાવીને શેર કરે છે.',
          nextActionHintEn: 'Next: Open Parties & Dispatch to bill buyers and track Khata.',
          nextActionHintGu: 'આગળ: ખરીદનારના બિલ અને ખાતાવહી માટે પાર્ટી અને ડિસ્પેચ ખોલો.',
          speechEn: 'Tap Export to share PDF or Excel reports. Next, manage Buyers and Dispatch Challans.',
          speechGu: 'એક્સપોર્ટ બટનથી PDF કે Excel રિપોર્ટ શેર કરી શકાય છે. આગળ, પાર્ટી અને ડિસ્પેચ ખાતાવહી જુઓ.',
        ),
      ],
    ),

    // Chapter 10: Parties, Buyers & Dispatch Challans
    GuideChapter(
      id: 'parties-dispatch',
      order: 10,
      screenId: GuideScreenId.parties,
      routePath: '/parties',
      iconKey: 'dispatch',
      titleEn: 'Buyers (Parties) & Dispatch Challans',
      titleGu: 'પાર્ટી (ખરીદનાર) અને ડિસ્પેચ ચલણ',
      summaryEn:
          'Manage buyers, dispatch finished lots with Challans, record Good/Damaged buyer returns, and collect Party Khata receipts.',
      summaryGu:
          'ખરીદનારની વિગતો, તૈયાર લોટનું ડિસ્પેચ ચલણ, પરત માલ અને પાર્ટી ખાતાવહીમાં જમા રકમનું સંચાલન કરો.',
      nextStepLabelEn: 'Next: Check Lot Profit & Loss & Direct Costs.',
      nextStepLabelGu: 'આગળ: લોટ નફો-નુકસાન અને સીધો ખર્ચ જુઓ.',
      relatedHelpTopicIds: ['parties-and-dispatch'],
      steps: [
        GuideStep(
          id: 'ch10_parties_create',
          chapterId: 'parties-dispatch',
          screenId: GuideScreenId.parties,
          routePath: '/parties',
          targetId: GuideTargetId.partiesNewAction,
          titleEn: 'Add Buyers & View Net Khata',
          titleGu: 'પાર્ટી ઉમેરો અને ચોખ્ખું ખાતું જુઓ',
          actionDescriptionEn:
              'Create Buyers/Agents with phone, GSTIN, and opening balance, then filter receivables vs advances.',
          actionDescriptionGu:
              'ફોન, GSTIN અને શરૂઆતના બેલેન્સ સાથે પાર્ટી ઉમેરો અને બાકી લેણું કે જમા ફિલ્ટર કરો.',
          nextActionHintEn:
              'Next: Open any Party to issue a Dispatch Challan or record Cash/UPI receipts.',
          nextActionHintGu:
              'આગળ: ડિસ્પેચ ચલણ બનાવવા અથવા રોકડ/UPI જમા નોંધવા કોઈપણ પાર્ટી ખોલો.',
          speechEn:
              'Add wholesale buyers here and monitor total receivable or advance balances at a glance.',
          speechGu:
              'અહીંથી ખરીદનાર ઉમેરો અને દરેક પાર્ટીનું બાકી લેણું કે એડવાન્સ સરળતાથી જુઓ.',
        ),
      ],
    ),

    // Chapter 11: Lot Profit & Loss (P&L) & Direct Costs
    GuideChapter(
      id: 'lot-pnl-costs',
      order: 11,
      screenId: GuideScreenId.lotDetail,
      routePath: '/lots',
      iconKey: 'profit',
      titleEn: 'Lot Profit & Loss (P&L) & Direct Costs',
      titleGu: 'લોટ નફો-નુકસાન (P&L) અને સીધો ખર્ચ',
      summaryEn:
          'Track exact per-lot profitability across Fabric, Labour, Direct Costs, Damage Loss, and Net Dispatched Sales.',
      summaryGu:
          'કાપડ, મજૂરી, સીધો ખર્ચ, ડેમેજ નુકસાન અને ચોખ્ખા વેચાણ મુજબ દરેક લોટનો નફો-નુકસાન જાણો.',
      nextStepLabelEn: 'Next: Configure Team Roles & Cloud Sync Health.',
      nextStepLabelGu: 'આગળ: ટીમ ભૂમિકાઓ અને ક્લાઉડ સિંક સુરક્ષા સેટ કરો.',
      relatedHelpTopicIds: ['lot-profit-and-loss'],
      steps: [
        GuideStep(
          id: 'ch11_lot_pnl',
          chapterId: 'lot-pnl-costs',
          screenId: GuideScreenId.lotDetail,
          routePath: '/lots',
          targetId: GuideTargetId.lotDetailPnl,
          titleEn: 'Add Direct Costs & Inspect Lot Margin',
          titleGu: 'સીધો ખર્ચ ઉમેરો અને લોટ માર્જિન જુઓ',
          actionDescriptionEn:
              'Record fabric, accessories, packaging, and transport bills on a Lot to calculate live realized profit %.',
          actionDescriptionGu:
              'લોટ પર કાપડ, એસેસરીઝ, પેકિંગ અને ભાડાનો ખર્ચ નોંધી લાઇવ નફો અને માર્જિન % જુઓ.',
          nextActionHintEn:
              'Tip: Direct Costs immediately refine per-piece cost and Lot P&L.',
          nextActionHintGu:
              'ટિપ: સીધો ખર્ચ ઉમેરતા જ પીસ દીઠ ખર્ચ અને લોટ P&L તરત અપડેટ થાય છે.',
          speechEn:
              'Inside any Lot Detail page, add Direct Costs like fabric or packaging to see true Lot Profit and Margin.',
          speechGu:
              'લોટની વિગતમાં કાપડ કે પેકિંગ જેવો સીધો ખર્ચ ઉમેરી સાચો નફો અને માર્જિન ટકાવારી જુઓ.',
        ),
      ],
    ),

    // Chapter 12: Team Roles, Cloud Sync & Conflict Resolution
    GuideChapter(
      id: 'team-sync-health',
      order: 12,
      screenId: GuideScreenId.team,
      routePath: '/settings/team',
      iconKey: 'team',
      titleEn: 'Team Roles, Cloud Sync & Conflict Resolution',
      titleGu: 'ટીમ ભૂમિકા, ક્લાઉડ સિંક અને વિવાદ ઉકેલ',
      summaryEn:
          'Invite workshop staff with role permissions, manage offline-first Cloud Sync, and resolve device conflicts cleanly.',
      summaryGu:
          'ભૂમિકા મુજબ સ્ટાફ આમંત્રિત કરો, ક્લાઉડ સિંક ચલાવો અને ઉપકરણ વચ્ચેના વિવાદ સુરક્ષિત રીતે ઉકેલો.',
      nextStepLabelEn:
          'Training Complete! You are ready to run your full StitchFlow v2 workshop.',
      nextStepLabelGu:
          'તાલીમ પૂર્ણ! હવે તમે સંપૂર્ણ StitchFlow v2 વર્કશોપ ચલાવવા તૈયાર છો.',
      relatedHelpTopicIds: ['team-rbac-sync-health'],
      steps: [
        GuideStep(
          id: 'ch12_team_roles',
          chapterId: 'team-sync-health',
          screenId: GuideScreenId.team,
          routePath: '/settings/team',
          targetId: GuideTargetId.teamInviteAction,
          titleEn: 'Staff Invite Codes & Role Management',
          titleGu: 'સ્ટાફ આમંત્રણ કોડ અને ભૂમિકા ફેરફાર',
          actionDescriptionEn:
              'Invite Managers, Supervisors, or Accountants with 8-char codes and promote or demote members anytime as Owner.',
          actionDescriptionGu:
              '૮-અક્ષરના કોડથી મેનેજર, સુપરવાઇઝર કે એકાઉન્ટન્ટ જોડો અને માલિક તરીકે ભૂમિકા બદલો.',
          nextActionHintEn:
              'Next: Open Cloud Sync to review queued offline writes or resolve any conflicts.',
          nextActionHintGu:
              'આગળ: બાકી ઓફલાઇન નોંધો કે વિવાદ ઉકેલવા ક્લાઉડ સિંક ખોલો.',
          speechEn:
              'Create staff invite codes and adjust role permissions safely from Team Management.',
          speechGu:
              'ટીમ મેનેજમેન્ટમાંથી સ્ટાફ કોડ બનાવો અને સભ્યોના અધિકાર સુરક્ષિત રીતે સંભાળો.',
        ),
        GuideStep(
          id: 'ch12_sync_health',
          chapterId: 'team-sync-health',
          screenId: GuideScreenId.sync,
          routePath: '/settings/sync',
          targetId: GuideTargetId.syncNowAction,
          titleEn: 'Cloud Sync, Devices & Conflict Inspector',
          titleGu: 'ક્લાઉડ સિંક, ઉપકરણો અને વિવાદ નિરીક્ષક',
          actionDescriptionEn:
              'Push local Drift changes to Supabase, check active devices, and compare side-by-side diffs if a conflict occurs.',
          actionDescriptionGu:
              'સ્થાનિક ફેરફારો ક્લાઉડમાં મોકલો, સક્રિય ઉપકરણો તપાસો અને વિવાદ વખતે બંને કિંમતો સરખાવી ઉકેલો.',
          nextActionHintEn:
              'Final Tip: Keep weekly local ZIP backups alongside Cloud Sync!',
          nextActionHintGu:
              'અંતિમ ટિપ: ક્લાઉડ સિંક સાથે દર અઠવાડિયે લોકલ ZIP બેકઅપ પણ લેતા રહો!',
          speechEn:
              'Monitor cloud sync status, check data health, and resolve conflicts side-by-side. You have finished the full v2 training!',
          speechGu:
              'અહીંથી ક્લાઉડ સિંક, ડેટા હેલ્થ અને વિવાદ નિરીક્ષક તપાસો. તમારી સંપૂર્ણ v2 તાલીમ પૂર્ણ થઈ!',
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
        actionDescriptionEn: 'Switch between Pending Returns waiting with workers, Live Good/Damaged Stock, complete Movement History, and Worker/Work Stage balances.',
        actionDescriptionGu: 'કારીગર પાસે બાકી માલ, લાઇવ સારો/ડેમેજ સ્ટોક, સંપૂર્ણ હેરફેર ઇતિહાસ અને કારીગર/તબક્કા સારાંશ વચ્ચે સ્વિચ કરો.',
        nextActionHintEn: 'Tip: Tap any Pending Return card to record returned pieces in seconds.',
        nextActionHintGu:
            'ટિપ: કોઈપણ બાકી પરત કાર્ડ પર ટેપ કરીને તરત પરત નોંધો.',
        speechEn: 'Use these Stock tabs to check pending returns, live inventory, full history, and worker summaries.',
        speechGu: 'આ સ્ટોક ટેબ્સથી બાકી પરત, લાઇવ સ્ટોક, ઇતિહાસ અને કારીગર સારાંશ જોઈ શકાય છે.',
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
        actionDescriptionEn: 'Switch between each worker\'s net balance, detailed earned labour entries, and all payment/advance records.',
        actionDescriptionGu: 'દરેક કારીગરનું ચોખ્ખું બેલેન્સ, કમાયેલ મજૂરીની વિગતો અને બધી ચુકવણી/એડવાન્સ નોંધો અલગ-અલગ જુઓ.',
        nextActionHintEn: 'Tip: Tap any worker card to inspect their full running ledger or add an audited adjustment.',
        nextActionHintGu: 'ટિપ: સંપૂર્ણ ખાતાવહી જોવા અથવા બોનસ/કપાત ઉમેરવા કોઈપણ કારીગર કાર્ડ પર ટેપ કરો.',
        speechEn: 'Switch tabs here to view Worker Accounts, Earned Labour, and Payment History. Tap any worker to open their full ledger.',
        speechGu: 'અહીંથી કારીગર ખાતા, કમાયેલ મજૂરી અને ચુકવણી ઇતિહાસ અલગ જોઈ શકાય છે. સંપૂર્ણ ખાતાવહી માટે કારીગર પર ટેપ કરો.',
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
        actionDescriptionEn: 'Swipe across Daily Workshop, Worker Performance, Stage Performance, Inventory, Labour & Financial, and Business Insights.',
        actionDescriptionGu: 'દૈનિક વર્કશોપ, કારીગર કામગીરી, તબક્કા કામગીરી, ઇન્વેન્ટરી, મજૂરી હિસાબ અને વ્યવસાયિક વિશ્લેષણ વચ્ચે સ્વિચ કરો.',
        nextActionHintEn: 'Tip: Use Business Insights to spot slow work stages and oldest pending work.',
        nextActionHintGu: 'ટિપ: કયા તબક્કામાં માલ અટક્યો છે તે જોવા "વ્યવસાયિક વિશ્લેષણ" ખોલો.',
        speechEn: 'Choose between six report categories including Daily Workshop, Worker Performance, Inventory, Financial, and Business Insights.',
        speechGu: 'અહીંથી દૈનિક વર્કશોપ, કારીગર કામગીરી, સ્ટોક, હિસાબ અને વ્યવસાયિક વિશ્લેષણ જેવા ૬ રિપોર્ટ જોઈ શકાય છે.',
      ),
    ],
    GuideScreenId.settings: <GuideStep>[
      const GuideStep(
        id: 'screen_settings_appearance',
        chapterId: 'business-setup',
        screenId: GuideScreenId.settings,
        routePath: '/settings',
        primaryTabIndex: 5,
        targetId: GuideTargetId.settingsAppearanceTile,
        titleEn: 'Language, Theme & Density',
        titleGu: 'ભાષા, થીમ અને દેખાવ',
        actionDescriptionEn: 'Switch anytime between English and ગુજરાતી, Light or Dark theme, and comfortable or compact spacing.',
        actionDescriptionGu: 'ગમે ત્યારે અંગ્રેજી અને ગુજરાતી ભાષા, લાઇટ કે ડાર્ક થીમ અને સ્ક્રીન સાઇઝ બદલો.',
        nextActionHintEn:
            'Next: Check Business Profile and Stock/Labour preferences below.',
        nextActionHintGu:
            'આગળ: નીચે બિઝનેસ પ્રોફાઇલ અને સ્ટોક/મજૂરી નિયમો જુઓ.',
        speechEn: 'Appearance lets you switch between English and Gujarati, light and dark themes, and display density.',
        speechGu: 'દેખાવ અને ભાષામાંથી તમે ગમે ત્યારે અંગ્રેજી કે ગુજરાતી અને લાઇટ કે ડાર્ક થીમ બદલી શકો છો.',
      ),
      ...chapters[1].steps,
      const GuideStep(
        id: 'screen_settings_security',
        chapterId: 'reports-history-safety',
        screenId: GuideScreenId.settings,
        routePath: '/settings',
        primaryTabIndex: 5,
        targetId: GuideTargetId.settingsSecurityTile,
        titleEn: 'App PIN & Biometric Lock',
        titleGu: 'App PIN અને ફિંગરપ્રિન્ટ લોક',
        actionDescriptionEn: 'Protects workshop rates, stock, and worker ledgers with a 4- or 6-digit offline PIN, fingerprint unlock, and recovery key.',
        actionDescriptionGu: 'કારખાનાના ભાવ, સ્ટોક અને હિસાબને ૪ કે ૬ અંકના ઓફલાઇન PIN અને ફિંગરપ્રિન્ટથી સુરક્ષિત રાખે છે.',
        nextActionHintEn:
            'Next: Protect your offline data with Backup & Restore.',
        nextActionHintGu: 'આગળ: બેકઅપ અને ડેટા સુરક્ષા વિકલ્પ જુઓ.',
        speechEn: 'Enable App PIN and Fingerprint Lock here to protect your workshop accounts on shared phones.',
        speechGu: 'તમારા ફોન પર કારખાનાના હિસાબને સુરક્ષિત રાખવા અહીંથી App PIN અને ફિંગરપ્રિન્ટ લોક ચાલુ કરી શકાય છે.',
      ),
      const GuideStep(
        id: 'screen_settings_backup',
        chapterId: 'reports-history-safety',
        screenId: GuideScreenId.settings,
        routePath: '/settings',
        primaryTabIndex: 5,
        targetId: GuideTargetId.settingsBackupTile,
        titleEn: 'Backup & Data Safety (.zip)',
        titleGu: 'બેકઅપ અને ડેટા સુરક્ષા (.zip)',
        actionDescriptionEn: 'Creates a full verified ZIP backup of your offline database and all lot photos so you can restore safely on any phone.',
        actionDescriptionGu: 'તમારા ઓફલાઇન ડેટાબેઝ અને બધા લોટ ફોટાનો સંપૂર્ણ ZIP બેકઅપ બનાવે છે જેથી કોઈપણ ફોનમાં સુરક્ષિત રિસ્ટોર કરી શકાય.',
        nextActionHintEn:
            'Next: Open Help & User Guide anytime to replay voice training.',
        nextActionHintGu: 'આગળ: અવાજ સાથેની સંપૂર્ણ તાલીમ ફરી જોવા "મદદ અને માર્ગદર્શન" ખોલો.',
        speechEn: 'Use Backup and Data Safety once a week to save a full ZIP backup of your database and photos.',
        speechGu: 'અઠવાડિયે એકવાર બેકઅપ અને ડેટા સુરક્ષામાંથી સંપૂર્ણ ZIP બેકઅપ બનાવીને સુરક્ષિત રાખો.',
      ),
      const GuideStep(
        id: 'screen_settings_help',
        chapterId: 'dashboard-overview',
        screenId: GuideScreenId.settings,
        routePath: '/settings',
        primaryTabIndex: 5,
        targetId: GuideTargetId.settingsHelpTile,
        titleEn: 'Interactive Training & User Guide Hub',
        titleGu: 'ઇન્ટરેક્ટિવ તાલીમ અને સંપૂર્ણ યુઝર ગાઇડ',
        actionDescriptionEn: 'Replay the 9-chapter guided training, launch live button tours for any screen, or listen to all 19 workshop guides in English or Gujarati.',
        actionDescriptionGu: '૯ પ્રકરણની સંપૂર્ણ તાલીમ ફરી જુઓ, કોઈપણ સ્ક્રીનનું લાઇવ માર્ગદર્શન શરૂ કરો અથવા ૧૯ વર્કશોપ ગાઇડ સાંભળો.',
        nextActionHintEn: 'Tip: You can also tap the (?) Guide icon in the top bar from any screen.',
        nextActionHintGu: 'ટિપ: કોઈપણ સ્ક્રીન પર ઉપરનું (?) માર્ગદર્શન બટન દબાવીને તરત ગાઇડ ખોલી શકાય છે.',
        speechEn: 'Help and User Guide holds the full nine-chapter interactive training and all nineteen voice-enabled guides.',
        speechGu: 'મદદ અને માર્ગદર્શનમાં ૯ પ્રકરણની લાઇવ તાલીમ અને ૧૯ સંપૂર્ણ વર્કશોપ ગાઇડ અવાજ સાથે ઉપલબ્ધ છે.',
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
        actionDescriptionEn: 'Add each Design code here, then add Colours with initial piece quantities and piece prices so stock becomes ready to issue.',
        actionDescriptionGu: 'અહીં દરેક ડિઝાઇન કોડ ઉમેરો અને તેની અંદર રંગ, શરૂઆતનો જથ્થો તથા ભાવ નોંધો જેથી સ્ટોક આપવા તૈયાર બને.',
        nextActionHintEn: 'Next: After adding Colours, use Stock Issue or Stage Routing to start production.',
        nextActionHintGu: 'આગળ: રંગ ઉમેર્યા પછી સ્ટોક આપો અથવા તબક્કા રૂટિંગ દ્વારા કામ શરૂ કરો.',
        speechEn: 'Tap Add Design to organize styles inside this lot, then add each colour and starting piece quantity.',
        speechGu: 'આ લોટમાં નવી ડિઝાઇન ઉમેરવા આ બટન દબાવો અને પછી દરેક રંગનો શરૂઆતનો જથ્થો ઉમેરો.',
      ),
      GuideStep(
        id: 'screen_lot_detail_routing',
        chapterId: 'lots-designs-colours',
        screenId: GuideScreenId.lotDetail,
        routePath: '/lots',
        targetId: GuideTargetId.lotDetailRouting,
        titleEn: 'Stage Routing & Progress',
        titleGu: 'તબક્કા રૂટિંગ અને પ્રગતિ',
        actionDescriptionEn: 'Track piece movement across multiple custom production stages and transfer completed pieces to the next work stage.',
        actionDescriptionGu: 'અલગ-અલગ તબક્કા વચ્ચે પીસની પ્રગતિ ટ્રેક કરો અને તૈયાર પીસ આગળના તબક્કામાં મોકલો.',
        nextActionHintEn:
            'Tip: Every Lot also keeps a full Production History timeline.',
        nextActionHintGu:
            'ટિપ: દરેક લોટનો સંપૂર્ણ પ્રોડક્શન ઇતિહાસ પણ અહીંથી જોઈ શકાય છે.',
        speechEn: 'Stage Routing shows stage-by-stage progress across your custom workshop work stages.',
        speechGu: 'તબક્કા રૂટિંગથી દરેક તબક્કામાં લોટની પ્રગતિ અને તબક્કાવાર સ્થિતિ જોઈ શકાય છે.',
      ),
    ],
    GuideScreenId.workerDetail: const <GuideStep>[
      GuideStep(
        id: 'screen_worker_assignments',
        chapterId: 'workers-and-rates',
        screenId: GuideScreenId.workerDetail,
        routePath: '/workers',
        targetId: GuideTargetId.workerDetailAssignments,
        titleEn: 'Assign Work Stages to Worker',
        titleGu: 'કારીગરને તબક્કો સોંપો',
        actionDescriptionEn: 'Select which work stages this karigar handles so they appear automatically during Stock Issue.',
        actionDescriptionGu: 'આ કારીગર કયા તબક્કાનું કામ કરે છે તે પસંદ કરો જેથી સ્ટોક આપતી વખતે તેમનું નામ આપમેળે દેખાય.',
        nextActionHintEn:
            'Next: Set their per-piece Rate for each assigned work stage.',
        nextActionHintGu: 'આગળ: સોંપેલા દરેક તબક્કા માટે પીસ દીઠ ભાવ સેટ કરો.',
        speechEn: 'Tap Manage Assignments to link this worker to the work stages they work on.',
        speechGu:
            'આ કારીગરને તેમના તબક્કા સાથે જોડવા તબક્કા સોંપણી પર ટેપ કરો.',
      ),
      GuideStep(
        id: 'screen_worker_rates',
        chapterId: 'workers-and-rates',
        screenId: GuideScreenId.workerDetail,
        routePath: '/workers',
        targetId: GuideTargetId.workerDetailRates,
        titleEn: 'Effective-Dated Piece Rates',
        titleGu: 'તારીખ મુજબ પીસ દીઠ ભાવ',
        actionDescriptionEn: 'Set or revise this worker\'s per-piece rate with an effective IST date. Old transactions keep their locked historical rate.',
        actionDescriptionGu: 'અમલી તારીખ સાથે પીસ દીઠ ભાવ સેટ કે અપડેટ કરો. જૂના વ્યવહારોનો લોક કરેલો ભાવ ક્યારેય બદલાતો નથી.',
        nextActionHintEn: 'Next: View Worker Ledger to check Earned Labour, Advances, and Net Payable.',
        nextActionHintGu:
            'આગળ: કમાયેલ મજૂરી, એડવાન્સ અને બાકી હિસાબ જોવા ખાતાવહી ખોલો.',
        speechEn: 'Use Rates to set effective-dated per-piece rates so future revisions never change past accounts.',
        speechGu: 'ભાવ વિભાગમાંથી અમલી તારીખ સાથે પીસ દીઠ ભાવ સેટ કરો જેથી જૂનો હિસાબ હંમેશા ચોક્કસ રહે.',
      ),
      GuideStep(
        id: 'screen_worker_ledger',
        chapterId: 'payments-ledger',
        screenId: GuideScreenId.workerDetail,
        routePath: '/workers',
        targetId: GuideTargetId.workerDetailLedger,
        titleEn: 'Worker Ledger & Account Statement',
        titleGu: 'કારીગર ખાતાવહી અને હિસાબ',
        actionDescriptionEn: 'Opens the complete running balance of earned labour, advances, regular payouts, and audited adjustments.',
        actionDescriptionGu: 'કમાયેલ મજૂરી, એડવાન્સ, નિયમિત ચુકવણી અને સમાયોજન સાથેની સંપૂર્ણ ચાલુ ખાતાવહી ખોલે છે.',
        nextActionHintEn: 'Tip: You can share a WhatsApp / print slip directly from the ledger.',
        nextActionHintGu:
            'ટિપ: ખાતાવહીમાંથી સીધી હિસાબ સ્લિપ શેર કે પ્રિન્ટ કરી શકાય છે.',
        speechEn:
            'Open Worker Ledger anytime for weekly or monthly wage settlement.',
        speechGu:
            'સાપ્તાહિક કે માસિક પગાર હિસાબ માટે અહીંથી કારીગરની ખાતાવહી ખોલો.',
      ),
    ],
    GuideScreenId.parties: chapters[9].steps,
    GuideScreenId.team: <GuideStep>[chapters[11].steps.first],
    GuideScreenId.sync: <GuideStep>[chapters[11].steps.last],
  };

  /// Flattened ordered list of every step across all 12 end-to-end chapters.
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
          primaryTabIndex: 5,
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
          primaryTabIndex: 5,
          nextTopicId: 'app-pin-and-biometrics',
        ),
        'app-pin-and-biometrics': HelpTopicActionLink(
          topicId: 'app-pin-and-biometrics',
          chapterId: 'reports-history-safety',
          liveRoutePath: '/settings',
          liveScreenId: GuideScreenId.settings,
          primaryTabIndex: 5,
          nextTopicId: 'pin-recovery-and-lock-safety',
        ),
        'pin-recovery-and-lock-safety': HelpTopicActionLink(
          topicId: 'pin-recovery-and-lock-safety',
          chapterId: 'reports-history-safety',
          liveRoutePath: '/settings',
          liveScreenId: GuideScreenId.settings,
          primaryTabIndex: 5,
          nextTopicId: 'local-reminders-notifications',
        ),
        'local-reminders-notifications': HelpTopicActionLink(
          topicId: 'local-reminders-notifications',
          chapterId: 'business-setup',
          liveRoutePath: '/settings',
          liveScreenId: GuideScreenId.settings,
          primaryTabIndex: 5,
          nextTopicId: 'parties-and-dispatch',
        ),
        'parties-and-dispatch': HelpTopicActionLink(
          topicId: 'parties-and-dispatch',
          chapterId: 'parties-dispatch',
          liveRoutePath: '/parties',
          liveScreenId: GuideScreenId.parties,
          nextTopicId: 'lot-profit-and-loss',
        ),
        'lot-profit-and-loss': HelpTopicActionLink(
          topicId: 'lot-profit-and-loss',
          chapterId: 'lot-pnl-costs',
          liveRoutePath: '/lots',
          liveScreenId: GuideScreenId.lotDetail,
          nextTopicId: 'team-rbac-sync-health',
        ),
        'team-rbac-sync-health': HelpTopicActionLink(
          topicId: 'team-rbac-sync-health',
          chapterId: 'team-sync-health',
          liveRoutePath: '/settings/team',
          liveScreenId: GuideScreenId.team,
          nextTopicId: null,
        ),
      };
}
