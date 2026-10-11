const express = require('express');
const cors = require('cors');
const { validateAutomaton, minimizeDFA } = require('./automataService');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// Endpoint 1: Automata string validation and execution path tracking
app.post('/api/validate', (req, res) => {
  try {
    const { initialState, acceptStates, transitions, inputString } = req.body;

    if (!initialState) {
      return res.status(400).json({ error: 'initialState is required' });
    }
    if (!Array.isArray(acceptStates)) {
      return res.status(400).json({ error: 'acceptStates must be an array' });
    }
    if (!Array.isArray(transitions)) {
      return res.status(400).json({ error: 'transitions must be an array' });
    }
    if (inputString === undefined || inputString === null || typeof inputString !== 'string') {
      return res.status(400).json({ error: 'inputString must be a string' });
    }

    const result = validateAutomaton({
      initialState,
      acceptStates,
      transitions,
      inputString
    });

    return res.status(200).json(result);
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Validation failed' });
  }
});

// Endpoint 2: DFA Optimization / Minimization
app.post('/api/minimize', (req, res) => {
  try {
    const { initialState, acceptStates, transitions, states } = req.body;

    if (!initialState) {
      return res.status(400).json({ error: 'initialState is required' });
    }
    if (!Array.isArray(acceptStates)) {
      return res.status(400).json({ error: 'acceptStates must be an array' });
    }
    if (!Array.isArray(transitions)) {
      return res.status(400).json({ error: 'transitions must be an array' });
    }

    const result = minimizeDFA({
      initialState,
      acceptStates,
      transitions,
      states
    });

    return res.status(200).json(result);
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Minimization failed' });
  }
});

app.listen(PORT, () => {
  console.log(`Automata Backend running on port ${PORT}`);
});
