const workouts = {
  strength: [
    ["Push-up ladder", "Controlled reps, chest to floor"],
    ["Split squat hold", "Thirty seconds each side"],
    ["Plank drag", "Keep hips square"],
    ["Backpack row", "Squeeze at the top"],
    ["Wall sit finisher", "No sliding, no bargaining"],
  ],
  cardio: [
    ["High knees", "Fast feet, tall chest"],
    ["Mountain climbers", "Drive knees under hips"],
    ["Skater jumps", "Stick the landing"],
    ["Burpee step-back", "Smooth, not sloppy"],
    ["Sprint in place", "Empty the tank"],
  ],
  mobility: [
    ["World's greatest stretch", "Move slowly through range"],
    ["Hip airplane", "Balance before speed"],
    ["Thoracic rotation", "Follow the hand with your eyes"],
    ["Cossack squat", "Keep the heel down"],
    ["Deep squat breathing", "Long exhales"],
  ],
};

const coachLines = {
  strength: [
    "The weights do not care about your excuses.",
    "Strong is built rep by rep. Start counting.",
    "Brace, move, repeat. That is the whole speech.",
  ],
  cardio: [
    "Breathe like you mean it. Move like time is chasing you.",
    "Your heart rate asked for drama. Give it some.",
    "Fast does not mean frantic. Stay sharp.",
  ],
  mobility: [
    "Move better today so tomorrow has fewer complaints.",
    "Slow reps still count. Lazy ones do not.",
    "Range first, ego never.",
  ],
};

const notes = {
  strength: ["Warm up shoulders", "Rest with purpose", "Own every rep"],
  cardio: ["Nose in, mouth out", "Keep landings quiet", "Recover standing"],
  mobility: ["No pain chasing", "Use long exhales", "Stay patient"],
};

let state = {
  focus: "strength",
  intensity: 4,
  minutes: 24,
};

const workoutList = document.querySelector("#workoutList");
const noteList = document.querySelector("#noteList");
const coachLine = document.querySelector("#coachLine");
const intensityInput = document.querySelector("#intensityInput");
const timeInput = document.querySelector("#timeInput");
const minutesStat = document.querySelector("#minutesStat");
const roundsStat = document.querySelector("#roundsStat");
const scoreStat = document.querySelector("#scoreStat");
const difficultyBadge = document.querySelector("#difficultyBadge");

function getDifficulty(intensity) {
  if (intensity <= 2) return "Steady";
  if (intensity === 3) return "Focused";
  if (intensity === 4) return "Hard";
  return "Savage";
}

function getRounds(minutes, intensity) {
  return Math.max(3, Math.round(minutes / 7) + Math.floor(intensity / 2));
}

function render() {
  const rounds = getRounds(state.minutes, state.intensity);
  const heat = Math.min(99, state.minutes * 2 + state.intensity * 9);
  const moves = workouts[state.focus].slice(0, Math.min(5, state.intensity + 1));
  const seconds = Math.round((state.minutes * 60) / (moves.length * rounds));
  const lines = coachLines[state.focus];

  minutesStat.textContent = state.minutes;
  roundsStat.textContent = rounds;
  scoreStat.textContent = heat;
  difficultyBadge.textContent = getDifficulty(state.intensity);
  coachLine.textContent = lines[(state.intensity + state.minutes) % lines.length];

  workoutList.innerHTML = moves
    .map(
      ([name, detail]) => `
        <li>
          <div>
            <div class="move-name">${name}</div>
            <div class="move-detail">${detail}</div>
          </div>
          <span class="move-time">${seconds}s</span>
        </li>
      `,
    )
    .join("");

  noteList.innerHTML = notes[state.focus]
    .map((note, index) => `<article class="note"><strong>${index + 1}.</strong>${note}</article>`)
    .join("");
}

document.querySelectorAll("[data-focus]").forEach((button) => {
  button.addEventListener("click", () => {
    state.focus = button.dataset.focus;
    document
      .querySelectorAll("[data-focus]")
      .forEach((item) => item.classList.toggle("is-active", item === button));
    render();
  });
});

intensityInput.addEventListener("input", (event) => {
  state.intensity = Number(event.target.value);
  render();
});

timeInput.addEventListener("input", (event) => {
  state.minutes = Number(event.target.value);
  render();
});

document.querySelector("#randomizeButton").addEventListener("click", () => {
  const focuses = Object.keys(workouts);
  state = {
    focus: focuses[Math.floor(Math.random() * focuses.length)],
    intensity: Math.floor(Math.random() * 5) + 1,
    minutes: [12, 16, 20, 24, 28, 32, 36, 40][Math.floor(Math.random() * 8)],
  };

  intensityInput.value = state.intensity;
  timeInput.value = state.minutes;
  document
    .querySelectorAll("[data-focus]")
    .forEach((button) => button.classList.toggle("is-active", button.dataset.focus === state.focus));
  render();
});

render();
