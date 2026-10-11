/**
 * automataService.js
 * Pure logic for Finite Automata simulation (validation) and DFA minimization.
 */

/**
 * Validates whether an input string is accepted by the automaton and returns the execution path.
 * Supports deterministic (DFA) and non-deterministic (NFA with epsilon) transitions via BFS traversal.
 *
 * @param {Object} params
 * @param {string} params.initialState
 * @param {string[]} params.acceptStates
 * @param {Array<{ from: string, to: string, symbol: string }>} params.transitions
 * @param {string} params.inputString
 * @returns {{ accepted: boolean, executionPath: string[] }}
 */
function validateAutomaton({ initialState, acceptStates = [], transitions = [], inputString = '' }) {
  if (!initialState) {
    throw new Error('initialState is required');
  }

  const str = inputString !== undefined && inputString !== null ? String(inputString) : '';
  const acceptSet = new Set(acceptStates);

  const isEpsilon = (symbol) => symbol === '' || symbol === 'ε' || symbol === 'epsilon' || symbol === 'λ';

  // BFS Queue stores: { state, index, path }
  const queue = [{ state: initialState, index: 0, path: [initialState] }];
  const visited = new Set();
  visited.add(`${initialState}:0`);

  let longestPath = [initialState];
  let acceptingPath = null;

  while (queue.length > 0) {
    const current = queue.shift();

    // Check if input is completely consumed and current state is an accepting state
    if (current.index === str.length && acceptSet.has(current.state)) {
      acceptingPath = current.path;
      break;
    }

    if (current.path.length > longestPath.length) {
      longestPath = current.path;
    }

    // 1. Process epsilon transitions (does not advance input index)
    for (const t of transitions) {
      if (t.from === current.state && isEpsilon(t.symbol)) {
        const key = `${t.to}:${current.index}`;
        if (!visited.has(key)) {
          visited.add(key);
          queue.push({
            state: t.to,
            index: current.index,
            path: [...current.path, t.to]
          });
        }
      }
    }

    // 2. Process symbol transitions (advances input index by 1)
    if (current.index < str.length) {
      const currentChar = str[current.index];
      for (const t of transitions) {
        if (t.from === current.state && t.symbol === currentChar) {
          const nextIndex = current.index + 1;
          const key = `${t.to}:${nextIndex}`;
          if (!visited.has(key)) {
            visited.add(key);
            const nextPath = [...current.path, t.to];
            queue.push({
              state: t.to,
              index: nextIndex,
              path: nextPath
            });
          }
        }
      }
    }
  }

  if (acceptingPath) {
    return {
      accepted: true,
      executionPath: acceptingPath
    };
  }

  return {
    accepted: false,
    executionPath: longestPath
  };
}

/**
 * Optimizes and minimizes a DFA using standard DFA minimization (Moore's partition refinement).
 *
 * Steps:
 * 1. Eliminate unreachable states from initialState.
 * 2. Form initial partition P0: accept states and non-accept states.
 * 3. Iteratively refine partitions based on transition signatures until convergence.
 * 4. Reconstruct minimized DFA graph structure.
 *
 * @param {Object} params
 * @param {string} params.initialState
 * @param {string[]} params.acceptStates
 * @param {Array<{ from: string, to: string, symbol: string }>} params.transitions
 * @param {string[]} [params.states]
 * @returns {{ states: string[], initialState: string, acceptStates: string[], transitions: Array<{ from: string, to: string, symbol: string }> }}
 */
function minimizeDFA({ initialState, acceptStates = [], transitions = [], states = [] }) {
  if (!initialState) {
    throw new Error('initialState is required');
  }

  // 1. Extract all states and alphabet
  const rawStateSet = new Set(
    states && states.length > 0
      ? states
      : [initialState, ...acceptStates, ...transitions.flatMap((t) => [t.from, t.to])]
  );

  const alphabet = Array.from(
    new Set(transitions.map((t) => t.symbol).filter((s) => s !== undefined && s !== null && s !== ''))
  ).sort();

  // 2. Reachable state elimination (BFS from initialState)
  const reachable = new Set();
  const queue = [initialState];
  reachable.add(initialState);

  while (queue.length > 0) {
    const current = queue.shift();
    for (const t of transitions) {
      if (t.from === current && !reachable.has(t.to)) {
        reachable.add(t.to);
        queue.push(t.to);
      }
    }
  }

  const reachableStates = Array.from(rawStateSet).filter((s) => reachable.has(s)).sort();
  const reachableAccept = acceptStates.filter((s) => reachable.has(s)).sort();
  const reachableNonAccept = reachableStates.filter((s) => !reachableAccept.includes(s)).sort();
  const reachableTransitions = transitions.filter((t) => reachable.has(t.from) && reachable.has(t.to));

  // Build transition lookup map: "state:::symbol" -> targetState
  const transitionMap = new Map();
  for (const t of reachableTransitions) {
    transitionMap.set(`${t.from}:::${t.symbol}`, t.to);
  }

  const getTarget = (state, symbol) => transitionMap.get(`${state}:::${symbol}`) || null;

  // 3. Initial Partition P0: [Accept States, Non-Accept States]
  let partition = [];
  if (reachableAccept.length > 0 && reachableNonAccept.length > 0) {
    partition = [reachableAccept, reachableNonAccept];
  } else if (reachableAccept.length > 0) {
    partition = [reachableAccept];
  } else {
    partition = [reachableNonAccept];
  }

  // 4. Partition refinement loop
  let changed = true;
  while (changed) {
    changed = false;
    const nextPartition = [];

    for (const group of partition) {
      if (group.length <= 1) {
        nextPartition.push(group);
        continue;
      }

      // Group states by their transition signature
      const subgroups = new Map();

      for (const state of group) {
        const signature = alphabet
          .map((symbol) => {
            const target = getTarget(state, symbol);
            if (!target) return '-1';
            const targetIndex = partition.findIndex((grp) => grp.includes(target));
            return String(targetIndex);
          })
          .join('|');

        if (!subgroups.has(signature)) {
          subgroups.set(signature, []);
        }
        subgroups.get(signature).push(state);
      }

      if (subgroups.size > 1) {
        changed = true;
      }

      for (const sub of subgroups.values()) {
        nextPartition.push(sub.sort());
      }
    }

    partition = nextPartition;
  }

  // Helper to determine state name for a partition group
  const getGroupName = (group) => (group.length === 1 ? group[0] : [...group].sort().join('_'));

  // 5. Reconstruct minimized DFA
  const newStates = partition.map(getGroupName).sort();

  const initialGroup = partition.find((grp) => grp.includes(initialState));
  const newInitialState = initialGroup ? getGroupName(initialGroup) : initialState;

  const newAcceptStates = partition
    .filter((grp) => grp.some((s) => reachableAccept.includes(s)))
    .map(getGroupName)
    .sort();

  const newTransitions = [];
  const addedTransitions = new Set();

  for (const group of partition) {
    const fromName = getGroupName(group);
    const representative = group[0];

    for (const symbol of alphabet) {
      const target = getTarget(representative, symbol);
      if (target) {
        const targetGroup = partition.find((grp) => grp.includes(target));
        if (targetGroup) {
          const toName = getGroupName(targetGroup);
          const transitionKey = `${fromName}:::${toName}:::${symbol}`;

          if (!addedTransitions.has(transitionKey)) {
            addedTransitions.add(transitionKey);
            newTransitions.push({
              from: fromName,
              to: toName,
              symbol: symbol
            });
          }
        }
      }
    }
  }

  return {
    states: newStates,
    initialState: newInitialState,
    acceptStates: newAcceptStates,
    transitions: newTransitions
  };
}

module.exports = {
  validateAutomaton,
  minimizeDFA
};
