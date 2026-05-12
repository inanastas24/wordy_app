import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

type MeaningInput = {
  meaning: string;
  meaningLanguage: string;
  translation?: string;
  translationLanguage?: string;
  partOfSpeech?: string;
};

type ExampleInput = {
  sourceText: string;
  targetText?: string;
  sourceLanguage: string;
  targetLanguage?: string;
};

type GenerateWordExplanationRequest = {
  word: string;
  translation: string;
  sourceLanguage: string;
  targetLanguage: string;
  preferredExplanationLanguage: string;
  meanings: MeaningInput[];
  examples: ExampleInput[];
  userId?: string;
  timestamp?: string;
};

type GenerateWordExplanationResponse = {
  explanation: string;
  language: string;
  style?: "plain_explanatory";
};

export const generateWordExplanation = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 30,
    memory: "512MiB",
    cors: true,
  },
  async (request): Promise<GenerateWordExplanationResponse> => {
    const data = request.data as Partial<GenerateWordExplanationRequest>;

    const payload = validatePayload(data);
    logger.info("generateWordExplanation:start", {
      word: payload.word,
      sourceLanguage: payload.sourceLanguage,
      targetLanguage: payload.targetLanguage,
      preferredExplanationLanguage: payload.preferredExplanationLanguage,
      meaningsCount: payload.meanings.length,
      examplesCount: payload.examples.length,
      uid: request.auth?.uid ?? payload.userId ?? null,
    });

    try {
      const prompt = buildPrompt(payload);
      const generated = await generateExplanationWithModel(prompt);
      const explanation = sanitizeExplanation(generated.explanation);

      if (!explanation) {
        throw new Error("Model returned empty explanation");
      }

      return {
        explanation,
        language: generated.language || payload.preferredExplanationLanguage,
        style: "plain_explanatory",
      };
    } catch (error) {
      logger.warn("generateWordExplanation:fallback", {
        message: error instanceof Error ? error.message : String(error),
        word: payload.word,
      });

      const fallback = buildFallbackExplanation(payload);
      return {
        explanation: fallback.explanation,
        language: fallback.language,
        style: "plain_explanatory",
      };
    }
  }
);

function validatePayload(
  data: Partial<GenerateWordExplanationRequest>
): GenerateWordExplanationRequest {
  const word = normalizeText(data.word);
  const translation = normalizeText(data.translation);
  const sourceLanguage = normalizeCode(data.sourceLanguage);
  const targetLanguage = normalizeCode(data.targetLanguage);
  const preferredExplanationLanguage = normalizeCode(
    data.preferredExplanationLanguage
  );

  if (!word) {
    throw new HttpsError("invalid-argument", "Missing word");
  }
  if (!sourceLanguage || !targetLanguage || !preferredExplanationLanguage) {
    throw new HttpsError(
      "invalid-argument",
      "Missing sourceLanguage, targetLanguage, or preferredExplanationLanguage"
    );
  }

  const meanings = Array.isArray(data.meanings)
    ? data.meanings
        .map(normalizeMeaning)
        .filter((item): item is MeaningInput => item !== null)
        .slice(0, 8)
    : [];

  const examples = Array.isArray(data.examples)
    ? data.examples
        .map(normalizeExample)
        .filter((item): item is ExampleInput => item !== null)
        .slice(0, 6)
    : [];

  return {
    word,
    translation,
    sourceLanguage,
    targetLanguage,
    preferredExplanationLanguage,
    meanings,
    examples,
    userId: normalizeText(data.userId),
    timestamp: normalizeText(data.timestamp),
  };
}

function normalizeMeaning(value: unknown): MeaningInput | null {
  if (!value || typeof value !== "object") {
    return null;
  }

  const input = value as Record<string, unknown>;
  const meaning = normalizeText(input.meaning);
  const meaningLanguage = normalizeCode(input.meaningLanguage);
  if (!meaning || !meaningLanguage) {
    return null;
  }

  return {
    meaning,
    meaningLanguage,
    translation: normalizeText(input.translation),
    translationLanguage: normalizeCode(input.translationLanguage),
    partOfSpeech: normalizeText(input.partOfSpeech),
  };
}

function normalizeExample(value: unknown): ExampleInput | null {
  if (!value || typeof value !== "object") {
    return null;
  }

  const input = value as Record<string, unknown>;
  const sourceText = normalizeText(input.sourceText);
  const sourceLanguage = normalizeCode(input.sourceLanguage);
  if (!sourceText || !sourceLanguage) {
    return null;
  }

  return {
    sourceText,
    targetText: normalizeText(input.targetText),
    sourceLanguage,
    targetLanguage: normalizeCode(input.targetLanguage),
  };
}

function normalizeText(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeCode(value: unknown): string {
  return typeof value === "string" ? value.trim().toLowerCase() : "";
}

function buildPrompt(payload: GenerateWordExplanationRequest): string {
  const meaningsJson = JSON.stringify(payload.meanings, null, 2);
  const examplesJson = JSON.stringify(payload.examples, null, 2);

  return [
    "You are a multilingual lexicography assistant inside a language-learning app.",
    "",
    "Your job is to explain what a word means in a way that helps a learner understand it and describe it to another person if they forget the exact word.",
    "",
    "Write natural, human-friendly explanations instead of dry dictionary definitions.",
    "",
    "Rules:",
    "- Use the requested output language exactly.",
    "- Prefer plain, intuitive wording.",
    "- Keep it concise: 1-2 sentences.",
    "- Base the explanation only on the provided meanings, translation, and examples.",
    "- If the word has several meanings, explain the most relevant/common meaning first.",
    "- If the word is abstract, explain the idea in simple everyday language.",
    "- If the word is concrete, describe what kind of thing/person/action it is.",
    "- Do not output markdown.",
    "- Do not output lists.",
    "- Return valid JSON only.",
    "",
    `Word: ${payload.word}`,
    `Translation: ${payload.translation}`,
    `Source language: ${payload.sourceLanguage}`,
    `Target language: ${payload.targetLanguage}`,
    `Preferred explanation language: ${payload.preferredExplanationLanguage}`,
    "",
    `Meanings:\n${meaningsJson}`,
    "",
    `Examples:\n${examplesJson}`,
    "",
    "Task:",
    "Write one short explanation of the word for a language learner.",
    "The explanation should help the learner understand the concept and explain it to another person in simple words.",
    "",
    "Return JSON:",
    JSON.stringify(
      {
        explanation: "...",
        language: payload.preferredExplanationLanguage,
      },
      null,
      2
    ),
  ].join("\n");
}

async function generateExplanationWithModel(
  prompt: string
): Promise<{ explanation: string; language: string }> {
  // TODO:
  // Replace this stub with your actual provider call.
  //
  // Example shape expected from the model:
  // {
  //   explanation: "Квітка — це частина рослини, яка ...",
  //   language: "uk"
  // }
  //
  // Good implementation options:
  // - OpenAI Responses API
  // - another structured-output LLM provider
  //
  // The provider should be configured to return strict JSON.

  throw new Error("Model provider not configured");
}

function buildFallbackExplanation(
  payload: GenerateWordExplanationRequest
): GenerateWordExplanationResponse {
  const preferred = payload.preferredExplanationLanguage;

  const preferredMeaning = payload.meanings.find(
    (item) =>
      item.translation &&
      item.translationLanguage === preferred &&
      item.translation.trim().length > 0
  );

  if (preferredMeaning?.translation) {
    return {
      explanation: sanitizeExplanation(preferredMeaning.translation),
      language: preferred,
      style: "plain_explanatory",
    };
  }

  const firstMeaning = payload.meanings.find((item) => item.meaning.trim().length > 0);
  if (firstMeaning) {
    return {
      explanation: sanitizeExplanation(firstMeaning.meaning),
      language: firstMeaning.meaningLanguage,
      style: "plain_explanatory",
    };
  }

  const translationFallback = payload.translation || payload.word;
  return {
    explanation: sanitizeExplanation(translationFallback),
    language: preferred || payload.targetLanguage || payload.sourceLanguage,
    style: "plain_explanatory",
  };
}

function sanitizeExplanation(text: string): string {
  return text
    .replace(/\s+/g, " ")
    .replace(/^["'\s]+|["'\s]+$/g, "")
    .trim()
    .slice(0, 320);
}
