import '../../../models/automaton_model.dart';
import 'lesson_models.dart';

/// Built-in educational modules. Additional lessons can be appended here
/// without touching the canvas, simulator, or automata engine.
class LessonCatalog {
  LessonCatalog._();

  static List<Lesson> get all => [
        conceptsFromZero,
        dfaEvenZerosBuild,
        guidedSimulator,
        nfaAndEpsilon,
        independentPractice,
      ];

  static Lesson? byId(String id) {
    for (final lesson in all) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  // ── 1. Concepts from zero ─────────────────────────────────────────
  static const Lesson conceptsFromZero = Lesson(
    id: 'concepts_from_zero',
    title: 'Finite automata from zero',
    subtitle: 'Alphabet, states, arrows, and accept/reject',
    level: 'Beginner',
    module: 'Foundations',
    steps: [
      LessonStep(
        id: 'c0',
        kind: LessonStepKind.explain,
        title: 'What problem are we solving?',
        body:
            'A finite automaton is a tiny machine that reads a string one symbol '
            'at a time and then answers a yes/no question: “Does this string '
            'belong to my language?”\n\n'
            'Example language: “binary strings with an even number of 0s”. '
            'The string 00 is yes. The string 0 is no. The string 11011 is yes '
            '(zero zeros).',
        whyRequired:
            'Every later DFA/NFA diagram is just a picture of this yes/no machine.',
        hints: [
          'Think of a turnstile or a vending machine: current mode + next coin → new mode.',
        ],
      ),
      LessonStep(
        id: 'c1',
        kind: LessonStepKind.question,
        title: 'Check: language vs machine',
        body:
            'Answer before the explanation is shown. A language is a set of strings. '
            'The automaton is a procedure that tries to recognize that set.',
        question: QuizQuestion(
          prompt:
              'If the language is “strings that end with 01”, which object is the language?',
          choices: [
            'The circle-and-arrow drawing on the canvas',
            'The infinite set of strings {01, 001, 101, 0001, …}',
            'The Simulate button',
            'The alphabet {0, 1}',
          ],
          correctIndex: 1,
          explanation:
              'The language is the set of strings. The drawing is one machine that '
              'tries to accept exactly those strings. The alphabet is only the '
              'allowed symbols.',
          mistakeFeedback: {
            0: 'The diagram is the machine, not the set of strings it accepts.',
            2: 'Simulate is a tool for watching the machine run, not the language.',
            3: 'The alphabet is the symbol inventory. The language is a subset of all strings over that alphabet.',
          },
        ),
        hints: [
          'A language can exist on paper with no diagram at all.',
          'Machines implement languages; they are not the languages themselves.',
        ],
      ),
      LessonStep(
        id: 'c2',
        kind: LessonStepKind.explain,
        title: 'The five ingredients',
        body:
            'A finite automaton needs:\n'
            '1. An alphabet Σ (here usually {0,1} or {a,b}).\n'
            '2. A finite set of states (the circles).\n'
            '3. One start state (incoming start arrow).\n'
            '4. A transition relation (labeled arrows).\n'
            '5. Accepting states (double circle).\n\n'
            'On this app: add states from the left dock, connect them, and mark '
            'Initial / Final in the inspector. The canvas already draws all of this.',
        whyRequired:
            'Missing any one of these makes simulation undefined or incomplete.',
        hints: [
          'If Simulate complains about an initial state, ingredient 3 is missing.',
        ],
      ),
      LessonStep(
        id: 'c3',
        kind: LessonStepKind.question,
        title: 'Check: why a start state?',
        body: 'Why must every machine have a unique start state for DFA simulation?',
        question: QuizQuestion(
          prompt: 'What does the start state represent?',
          choices: [
            'The last symbol of the input',
            'The machine’s memory before any symbol is read',
            'A state that must always accept',
            'A decoration that only affects layout',
          ],
          correctIndex: 1,
          explanation:
              'Before reading, we have seen the empty prefix. The start state is '
              'the memory for “I have read nothing yet”. For even-number-of-0s, '
              'that memory is “even so far”, so the start state is accepting.',
          mistakeFeedback: {
            0: 'The last symbol is discovered only after reading; start is before reading.',
            2: 'Start states are accepting only when the empty string is in the language.',
            3: 'Layout is visual. Start is part of the formal definition.',
          },
        ),
        hints: [
          'Ask: after reading the empty string, should we accept?',
        ],
      ),
      LessonStep(
        id: 'c4',
        kind: LessonStepKind.question,
        title: 'DFA vs NFA in one sentence',
        body:
            'A DFA has, from each state, exactly one outgoing arrow per alphabet '
            'symbol. An NFA may have several, or none, and an ε-NFA may jump '
            'without consuming a symbol.',
        question: QuizQuestion(
          prompt: 'Which statement is true?',
          choices: [
            'Every NFA can be simulated, but a DFA cannot have loops',
            'In a DFA, reading a symbol from a state leads to at most one next state',
            'ε-arrows consume the next input symbol',
            'Accepting states are only allowed in NFAs',
          ],
          correctIndex: 1,
          explanation:
              'Deterministic means the next state is unique. NFAs may branch. '
              'ε-transitions move without reading. Both DFA and NFA may accept.',
          mistakeFeedback: {
            0: 'DFAs can (and often must) have self-loops.',
            2: 'ε means “free jump”: the input head does not move.',
            3: 'DFA accepting states are the double circles you already use.',
          },
        ),
        hints: [
          'Look at the DFA / NFA / ε-NFA chips in the top bar — they name this distinction.',
        ],
      ),
      LessonStep(
        id: 'c5',
        kind: LessonStepKind.complete,
        title: 'Foundations complete',
        body:
            'You can name the parts of a machine and say why start and accept '
            'states exist. Next: build a real DFA on the existing canvas.',
      ),
    ],
  );

  // ── 2. Guided DFA construction ────────────────────────────────────
  static const Lesson dfaEvenZerosBuild = Lesson(
    id: 'build_even_zeros',
    title: 'Build: even number of 0s',
    subtitle: 'Step-by-step DFA on the live canvas',
    level: 'Beginner',
    module: 'Construction',
    steps: [
      LessonStep(
        id: 'b0',
        kind: LessonStepKind.explain,
        title: 'What memory do we need?',
        body:
            'We only need to remember whether the count of 0s so far is even or odd. '
            'That is two buckets of history, so we will use two states.\n\n'
            'Ones do not change the count of zeros, so they should not change the '
            'even/odd memory.',
        whyRequired:
            'If you invent extra memory (for example “last symbol was 1”), the DFA '
            'gets bigger than this language needs.',
        hints: [
          'Parity of zeros is a single bit of information: even or odd.',
        ],
      ),
      LessonStep(
        id: 'b1',
        kind: LessonStepKind.canvasCheck,
        title: 'Place two states',
        body:
            'On the canvas, add two ordinary states (left dock → State, twice). '
            'Do not worry about names yet. Then tap Check construction.',
        whyRequired:
            'q_even = “seen an even number of 0s”. q_odd = “seen an odd number”. '
            'No other memory is required.',
        hints: [
          'Use the State tool twice. You should see two circles.',
          'If a previous machine is in the way, you can clear the canvas from the dock, then add two fresh states.',
        ],
        canvasGoal: CanvasGoal(
          minStates: 2,
          successMessage: 'Two states are on the canvas. That matches even/odd memory.',
        ),
      ),
      LessonStep(
        id: 'b2',
        kind: LessonStepKind.canvasCheck,
        title: 'Choose the start state',
        body:
            'Tap one state and mark it Initial. That state means “even number of '
            'zeros so far”, because we have read nothing yet (zero is even).',
        whyRequired:
            'The start state is the memory for the empty prefix. Empty has zero '
            'zeros, which is even, so start = even.',
        hints: [
          'Open the state inspector and enable Initial.',
          'Only one start state is allowed; the app already enforces that.',
        ],
        canvasGoal: CanvasGoal(
          minStates: 2,
          requireInitial: true,
          successMessage: 'Start state is set. The machine now knows where reading begins.',
        ),
      ),
      LessonStep(
        id: 'b3',
        kind: LessonStepKind.canvasCheck,
        title: 'Who should accept?',
        body:
            'The language includes every string whose total number of 0s is even, '
            'including the empty string. So the even/start state must be accepting. '
            'Mark that state Final.',
        whyRequired:
            'Accepting = “if the input ends here, say yes”. Ending in even-count '
            'must be yes; ending in odd-count must be no.',
        hints: [
          'Final/accepting is the double-circle indicator you already use.',
          'If you mark the odd state accepting instead, strings like 0 would be accepted.',
        ],
        canvasGoal: CanvasGoal(
          minStates: 2,
          requireInitial: true,
          requireAccepting: true,
          successMessage: 'An accepting state is marked. Next we wire the arrows.',
        ),
      ),
      LessonStep(
        id: 'b4',
        kind: LessonStepKind.canvasCheck,
        title: 'Arrows for 0 (the bit that flips parity)',
        body:
            'Connect the two states both ways with symbol 0: even --0--> odd and '
            'odd --0--> even. A 0 always flips even/odd.',
        whyRequired:
            'Without these arrows the machine cannot update the only fact it stores.',
        hints: [
          'Use connect mode: tap a state, drag to the other, type 0.',
          'You need two different-state arrows labeled 0, not a 0 self-loop on even.',
        ],
        canvasGoal: CanvasGoal(
          minStates: 2,
          requireInitial: true,
          requireAccepting: true,
          requiredSymbols: ['0'],
          requireCrossTransition: true,
          successMessage: 'A 0-arrow between different states is present.',
        ),
      ),
      LessonStep(
        id: 'b5',
        kind: LessonStepKind.canvasCheck,
        title: 'Arrows for 1 (the bit that stays)',
        body:
            'Add self-loops labeled 1 on both states. A 1 does not change the '
            'zero-count parity, so memory stays put.',
        whyRequired:
            'A DFA over {0,1} must define a next state for 1 as well as 0. Missing '
            '1-loops would make the machine incomplete.',
        hints: [
          'Self-loop: connect a state to itself and enter 1.',
          'Do this for both even and odd.',
        ],
        canvasGoal: CanvasGoal(
          minStates: 2,
          requireInitial: true,
          requireAccepting: true,
          requiredSymbols: ['0', '1'],
          requireSelfLoop: true,
          requireCrossTransition: true,
          successMessage: '0-flips and 1-stays are both represented. Testing the language next.',
        ),
      ),
      LessonStep(
        id: 'b6',
        kind: LessonStepKind.canvasCheck,
        title: 'Does the language match?',
        body:
            'Keep DFA selected. Check construction runs the same on-device engine '
            'the Simulate panel uses. It will try several strings.',
        whyRequired:
            'Structure is not enough: the start/accept combination must actually '
            'accept even counts and reject odd counts.',
        hints: [
          'Empty and strings of only 1s should accept (zero zeros).',
          'A single 0 should reject. Two 0s should accept.',
          'If 0 is accepted, your start state is probably not the even/accepting one, or a 0-loop stays in accept.',
        ],
        canvasGoal: CanvasGoal(
          requiredType: AutomatonType.dfa,
          minStates: 2,
          requireInitial: true,
          requireAccepting: true,
          requiredSymbols: ['0', '1'],
          languageCases: [
            LanguageCase(
              input: '',
              shouldAccept: true,
              why: 'Empty string has zero 0s (even). Start must be accepting.',
            ),
            LanguageCase(
              input: '1',
              shouldAccept: true,
              why: 'No zeros yet, still even. 1 should loop on the even/accept state.',
            ),
            LanguageCase(
              input: '0',
              shouldAccept: false,
              why: 'One zero is odd. 0 from start must leave the accepting state.',
            ),
            LanguageCase(
              input: '00',
              shouldAccept: true,
              why: 'Two zeros return to even.',
            ),
            LanguageCase(
              input: '10',
              shouldAccept: false,
              why: 'Still one zero; 1 should not hide that fact.',
            ),
            LanguageCase(
              input: '1001',
              shouldAccept: true,
              why: 'Two zeros, even, with 1s in between.',
            ),
          ],
          successMessage:
              'The engine agrees: even counts accept, odd counts reject. This is a correct even-0s DFA.',
        ),
      ),
      LessonStep(
        id: 'b7',
        kind: LessonStepKind.complete,
        title: 'Construction complete',
        body:
            'You built a DFA by asking “what must I remember?”, turning each '
            'answer into a state, and justifying every arrow. The Library still '
            'has a polished Even Number of 0s preset if you want to compare layouts.',
      ),
    ],
  );

  // ── 3. Guided simulator ───────────────────────────────────────────
  static const Lesson guidedSimulator = Lesson(
    id: 'guided_simulator',
    title: 'Watch a DFA run',
    subtitle: 'Use the existing Simulate drawer on a known machine',
    level: 'Beginner',
    module: 'Simulation',
    steps: [
      LessonStep(
        id: 's0',
        kind: LessonStepKind.explain,
        title: 'The tape and the head',
        body:
            'Simulation does not change your diagram. It walks the existing '
            'arrows. Open Simulate (top-right or the bottom Simulate tab). '
            'The input is a tape; the glowing state is “where we are now”.',
        whyRequired:
            'Seeing the path is how you debug a wrong accept/reject decision.',
        hints: [
          'The Simulate control you already use is the right one — this lesson does not replace it.',
        ],
      ),
      LessonStep(
        id: 's1',
        kind: LessonStepKind.simulate,
        title: 'Load Even 0s and try 00',
        body:
            'Load the Library preset “Even Number of 0s” (or keep the DFA you just built). '
            'Type 00, run Simulate, and step through. You should visit even → odd → even '
            'and finish accepted.',
        whyRequired:
            'Two zeros flip parity twice and return to the accepting even state.',
        hints: [
          'If you are not looking at Even 0s, open Library and load that preset.',
          'Use step forward after Run so you can see each state in the path.',
        ],
        simulateGoal: SimulateGoal(
          loadPresetId: 'even_zeros',
          suggestedInput: '00',
          expectAccepted: true,
          why: '00 has two zeros (even), so the engine must accept.',
        ),
      ),
      LessonStep(
        id: 's2',
        kind: LessonStepKind.simulate,
        title: 'Now try a rejecting string',
        body:
            'Run 000 (or 0). The last state should be the odd/non-accepting one. '
            'Rejection is not a crash — it is a legal finish outside an accept state.',
        whyRequired:
            'Learners often think “rejected” means the diagram is broken. It means '
            'the string is not in the language.',
        hints: [
          'Three zeros: even → odd → even → odd. Stop on odd = reject.',
        ],
        simulateGoal: SimulateGoal(
          loadPresetId: 'even_zeros',
          suggestedInput: '000',
          expectAccepted: false,
          why: 'Three zeros is odd, so the engine must reject.',
        ),
      ),
      LessonStep(
        id: 's3',
        kind: LessonStepKind.simulate,
        title: 'NFA branching (optional peek)',
        body:
            'Load Library → “Ends with 01 or 10 (NFA)”. Run 01. An NFA may keep '
            'several possible “current states”. The engine still reports accepted '
            'if any path succeeds.',
        whyRequired:
            'This is why NFAs feel like guessing: extra arrows are extra possible lives.',
        hints: [
          'Stay on NFA type when that preset is loaded; the chip will follow the preset.',
        ],
        simulateGoal: SimulateGoal(
          loadPresetId: 'nfa_branching',
          suggestedInput: '01',
          expectAccepted: true,
          why: '01 is one of the two target suffixes, so some NFA path must accept.',
        ),
      ),
      LessonStep(
        id: 's4',
        kind: LessonStepKind.complete,
        title: 'Simulation complete',
        body:
            'You used the real simulator, not a fake one. Keep using step playback '
            'whenever a string surprises you.',
      ),
    ],
  );

  // ── 4. NFA and epsilon ────────────────────────────────────────────
  static const Lesson nfaAndEpsilon = Lesson(
    id: 'nfa_epsilon_module',
    title: 'NFA and ε-NFA',
    subtitle: 'Branching and free jumps',
    level: 'Intermediate',
    module: 'Nondeterminism',
    steps: [
      LessonStep(
        id: 'n0',
        kind: LessonStepKind.explain,
        title: 'Why allow extra arrows?',
        body:
            'Sometimes it is easier to say “guess which suffix we are matching” '
            'than to encode every prefix in a DFA. Extra 0-arrows from one state '
            'are legal in an NFA. The type chip must be NFA, not DFA.',
        whyRequired:
            'If you leave the chip on DFA while drawing two 0-arrows from one state, '
            'you are drawing an NFA with the wrong label.',
        hints: [
          'Library preset “Ends with 01 or 10” is the picture of this idea.',
        ],
      ),
      LessonStep(
        id: 'n1',
        kind: LessonStepKind.question,
        title: 'Check: multiple arrows',
        body: 'From start, an NFA for “ends with 01 or 10” may loop on 0 and also branch on 0.',
        question: QuizQuestion(
          prompt: 'If two arrows labeled 0 leave the same state, the machine is…',
          choices: [
            'An invalid DFA, but a valid NFA',
            'Always a syntax error',
            'Required to accept every string',
            'The same as an ε-NFA',
          ],
          correctIndex: 0,
          explanation:
              'DFA forbids two 0-successors. NFA allows it (the engine explores both). '
              'ε-NFA is a further extension with unlabeled/ε jumps.',
          mistakeFeedback: {
            1: 'The canvas and engine allow it — switch the type to NFA.',
            2: 'Extra arrows add possible paths; they do not auto-accept everything.',
            3: 'Multiple labeled arrows are ordinary NFA, not necessarily epsilon.',
          },
        ),
        hints: [
          'Deterministic = at most one next state per symbol.',
        ],
      ),
      LessonStep(
        id: 'n2',
        kind: LessonStepKind.explain,
        title: 'Epsilon means “teleport”',
        body:
            'An ε-transition does not consume input. It is a free change of state. '
            'The Union (a* | b*) preset jumps from start to an a-loop world or a '
            'b-loop world, then stays there. Mixing a and b after that fails.',
        whyRequired:
            'Without ε, encoding union often needs a more awkward start gadget.',
        hints: [
          'Empty string is accepted there because both a* and b* contain ε, via ε then an accepting state.',
        ],
      ),
      LessonStep(
        id: 'n3',
        kind: LessonStepKind.simulate,
        title: 'Run the ε-NFA on aaa',
        body:
            'Load “Union (a* | b*) (ε-NFA)” from Library. Simulate aaa — it should '
            'accept via the ε-jump into the a-loop. Then try ab on your own: mixing '
            'a and b should fail because each ε-branch only loops on one letter.',
        simulateGoal: SimulateGoal(
          loadPresetId: 'epsilon_nfa',
          suggestedInput: 'aaa',
          expectAccepted: true,
          why: 'aaa is in a*, reached by an ε-jump into the accepting a-loop state.',
        ),
        hints: [
          'Also try b, empty, and ab in the same Simulate drawer.',
        ],
      ),
      LessonStep(
        id: 'n4',
        kind: LessonStepKind.complete,
        title: 'Nondeterminism module complete',
        body:
            'You can tell DFA, NFA, and ε-NFA apart and you know why extra arrows '
            'and ε-jumps exist. Minimization in the top bar remains a DFA-only tool.',
      ),
    ],
  );

  // ── 5. Independent practice ───────────────────────────────────────
  static const Lesson independentPractice = Lesson(
    id: 'practice_ends_with_01',
    title: 'Practice: ends with 01',
    subtitle: 'Build it yourself, then let the engine grade you',
    level: 'Practice',
    module: 'Independent',
    steps: [
      LessonStep(
        id: 'p0',
        kind: LessonStepKind.explain,
        title: 'Your brief',
        body:
            'Build a DFA over {0,1} that accepts exactly the strings ending in 01. '
            'Hint in your head, not on the canvas yet: you must remember “how much '
            'of 01 have I matched at the very end?”\n\n'
            'Typical memory: saw nothing useful / just saw a trailing 0 / just saw 01.',
        whyRequired:
            'Those three memories become three states. The last one is accepting.',
        hints: [
          'Need more? Think about what happens if after 01 you read another 0 or 1.',
          'Library has a reference machine named Ends with 01 — try not to load it until you have attempted yours.',
        ],
      ),
      LessonStep(
        id: 'p1',
        kind: LessonStepKind.question,
        title: 'Plan the states before drawing',
        body: 'Answer this before you copy a diagram.',
        question: QuizQuestion(
          prompt: 'After reading 010, which “progress on suffix 01” should you remember?',
          choices: [
            'I currently end with 01, so I should stay in the accept state',
            'I currently end with 0 (the last symbol), so I am in the “seen 0” state',
            'I must restart from a blank machine with no states',
            'I have failed forever and should have no outgoing arrows',
          ],
          correctIndex: 1,
          explanation:
              '010 ends with a 0, not with 01. From accept, 0 usually goes back to '
              'the “I have 0” state because that 0 might begin a new 01.',
          mistakeFeedback: {
            0: '010 ends with 0, so the suffix 01 is broken; you should not remain accepting.',
            2: 'The machine keeps running; it does not wipe states mid-string.',
            3: 'DFAs almost always keep going — a later 1 could still finish 01.',
          },
        ),
        hints: [
          'Look only at the end of 010.',
        ],
      ),
      LessonStep(
        id: 'p2',
        kind: LessonStepKind.canvasCheck,
        title: 'Build and grade',
        body:
            'Draw your DFA on the canvas (type chip DFA). When you think it is '
            'done, Check construction. The existing engine will test several strings. '
            'Wrong accept/reject answers include a reason, not just a red mark.',
        whyRequired:
            'Independent practice is the goal: the coach only grades, it does not draw for you.',
        hints: [
          'You likely need three states and a complete {0,1} table from each.',
          '01, 001, 1101 must accept. 0, 1, 00, 10, 0110 must reject.',
          'If 10 is accepted, you probably treat any 0 as success.',
        ],
        canvasGoal: CanvasGoal(
          requiredType: AutomatonType.dfa,
          minStates: 3,
          requireInitial: true,
          requireAccepting: true,
          requiredSymbols: ['0', '1'],
          languageCases: [
            LanguageCase(input: '01', shouldAccept: true, why: 'The shortest string in the language.'),
            LanguageCase(input: '001', shouldAccept: true, why: 'Still ends with 01.'),
            LanguageCase(input: '1101', shouldAccept: true, why: 'Prefix junk is allowed; only the suffix matters.'),
            LanguageCase(input: '', shouldAccept: false, why: 'Empty does not end with 01.'),
            LanguageCase(input: '0', shouldAccept: false, why: 'Only a prefix of 01.'),
            LanguageCase(input: '1', shouldAccept: false, why: 'Does not end with 01.'),
            LanguageCase(input: '00', shouldAccept: false, why: 'Ends with 0, not 01.'),
            LanguageCase(input: '10', shouldAccept: false, why: 'Ends with 10, the other suffix.'),
            LanguageCase(input: '010', shouldAccept: false, why: 'Ends with 0 after a successful 01.'),
          ],
          successMessage:
              'Practice passed. Your DFA agrees with the engine on the ends-with-01 tests.',
        ),
      ),
      LessonStep(
        id: 'p3',
        kind: LessonStepKind.complete,
        title: 'You can work independently',
        body:
            'Open Library anytime to compare with the reference machine, or keep '
            'designing new languages on the same canvas. New lessons can be added '
            'to the Learn catalog using this same step format.',
      ),
    ],
  );
}
