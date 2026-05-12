# `generateWordExplanation` Cloud Function

## Purpose

Generate a short, natural explanation of a word so the learner can:

- understand what the word means
- explain the idea to another person if they forget the exact word
- get a human-friendly paraphrase, not only a dry dictionary definition

The function should work for any language pair supported by the app.

## Callable Name

`generateWordExplanation`

## Request Payload

```json
{
  "word": "flower",
  "translation": "квітка",
  "sourceLanguage": "en",
  "targetLanguage": "uk",
  "preferredExplanationLanguage": "uk",
  "meanings": [
    {
      "meaning": "reproductive part of a plant with colorful petals",
      "meaningLanguage": "en",
      "translation": "репродуктивна частина рослини з яскравими пелюстками",
      "translationLanguage": "uk",
      "partOfSpeech": "noun"
    }
  ],
  "examples": [
    {
      "sourceText": "The flower attracts bees with its bright colors.",
      "targetText": "Квітка приваблює бджіл своїми яскравими кольорами.",
      "sourceLanguage": "en",
      "targetLanguage": "uk"
    }
  ],
  "userId": "optional-user-id",
  "timestamp": "2026-05-04T12:00:00Z"
}
```

## Response Payload

```json
{
  "explanation": "Квітка — це частина рослини, яка з’являється під час цвітіння і зазвичай має пелюстки. Саме з квітки згодом може утворитися плід або насіння.",
  "language": "uk",
  "style": "plain_explanatory"
}
```

Minimal required fields:

```json
{
  "explanation": "string",
  "language": "string"
}
```

## Output Requirements

The explanation must:

- be in `preferredExplanationLanguage`
- sound natural and easy to understand
- explain the concept, not just repeat the translation
- help the learner paraphrase the word in conversation
- stay concise: usually 1-2 sentences
- avoid markdown
- avoid bullet points
- avoid quoting the input word too many times

The explanation must not:

- return a raw dictionary definition unless absolutely necessary
- be overly academic unless the meaning itself is technical
- invent meanings not supported by the provided `meanings` or `examples`
- mention that it is an AI explanation

## Recommended Prompt Strategy

### System Prompt

```text
You are a multilingual lexicography assistant inside a language-learning app.

Your job is to explain what a word means in a way that helps a learner understand it and describe it to another person if they forget the exact word.

Write natural, human-friendly explanations instead of dry dictionary definitions.

Rules:
- Use the requested output language exactly.
- Prefer plain, intuitive wording.
- Keep it concise: 1-2 sentences.
- Base the explanation only on the provided meanings, translation, and examples.
- If the word has several meanings, explain the most relevant/common meaning first.
- If the word is abstract, explain the idea in simple everyday language.
- If the word is concrete, describe what kind of thing/person/action it is.
- Do not output markdown.
- Do not output lists.
- Return valid JSON only.
```

### User Prompt Template

```text
Word: {{word}}
Translation: {{translation}}
Source language: {{sourceLanguage}}
Target language: {{targetLanguage}}
Preferred explanation language: {{preferredExplanationLanguage}}

Meanings:
{{meanings_json}}

Examples:
{{examples_json}}

Task:
Write one short explanation of the word for a language learner.
The explanation should help the learner understand the concept and explain it to another person in simple words.

Return JSON:
{
  "explanation": "...",
  "language": "{{preferredExplanationLanguage}}"
}
```

## Meaning Selection Guidance

If multiple meanings are present:

- prefer the most common, neutral meaning
- deprioritize slang, vulgar, rare, archaic, or region-specific senses unless they are clearly the only available meaning
- if examples strongly point to one sense, use that sense

## Examples

### `flower` -> `uk`

Good:

```json
{
  "explanation": "Квітка — це частина рослини, яка зазвичай має пелюстки й з’являється під час цвітіння. Саме з неї потім може утворитися плід або насіння.",
  "language": "uk"
}
```

### `chica` -> `uk`

Good:

```json
{
  "explanation": "Це слово означає дівчину або молоду жінку. Ним зазвичай називають особу жіночої статі в неформальному або звичайному повсякденному мовленні.",
  "language": "uk"
}
```

### `freedom` -> `pl`

Good:

```json
{
  "explanation": "To stan, w którym człowiek może sam decydować o sobie i działać bez niepotrzebnych ograniczeń. Chodzi o możliwość wyboru i niezależność.",
  "language": "pl"
}
```

## Suggested Backend Validation

Before returning:

- trim whitespace
- ensure `explanation` is not empty
- ensure `language == preferredExplanationLanguage` unless there is an explicit fallback reason
- reject outputs longer than about 320 characters unless the word is clearly technical

## Fallback Behavior

If generation fails:

1. Return a normalized explanation built from the first available meaning in `preferredExplanationLanguage` if available.
2. Otherwise return the first available source meaning.
3. Never return an empty `explanation` if there is at least one meaning.

## Suggested Function Skeleton

```ts
type GenerateWordExplanationRequest = {
  word: string;
  translation: string;
  sourceLanguage: string;
  targetLanguage: string;
  preferredExplanationLanguage: string;
  meanings: Array<{
    meaning: string;
    meaningLanguage: string;
    translation?: string;
    translationLanguage?: string;
    partOfSpeech?: string;
  }>;
  examples: Array<{
    sourceText: string;
    targetText?: string;
    sourceLanguage: string;
    targetLanguage?: string;
  }>;
  userId?: string;
  timestamp?: string;
};

type GenerateWordExplanationResponse = {
  explanation: string;
  language: string;
  style?: "plain_explanatory";
};
```

## Product Note

This function is not meant to replace dictionary meanings.

Dictionary meanings answer:

- "What does this word mean?"

This function should answer:

- "How would I explain this word to another person in simple language?"
